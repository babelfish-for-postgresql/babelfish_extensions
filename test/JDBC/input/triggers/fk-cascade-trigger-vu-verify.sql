-- TEST 1: Basic CASCADE DELETE - trigger should fire once seeing all 5 deleted rows, not 5 times
INSERT INTO babel7022_parent SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
GO

INSERT INTO babel7022_child (id, parent_id) SELECT 1,1 UNION SELECT 2,2 UNION SELECT 3,3 UNION SELECT 4,4 UNION SELECT 5,5
GO

DELETE FROM babel7022_parent
GO

-- fire_count should be exactly 1 row (trigger fired once) with rows_seen = 5,
-- proving single-fire rather than 5 firings of 1 row each
SELECT COUNT(*) AS fire_count, MAX(rows_seen) AS rows_seen_per_fire FROM babel7022_fire_count
GO

SELECT COUNT(*) AS history_count FROM babel7022_history
GO

SELECT id, parent_id FROM babel7022_history ORDER BY id
GO

-- TEST 2: Single parent cascading to 10 children - trigger should fire once with all 10 rows
INSERT INTO babel7022_parent2 VALUES (1)
GO

INSERT INTO babel7022_child2 (parent_id, val)
  SELECT 1, 'child_' + CAST(n AS varchar)
  FROM (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
        UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) t
GO

DELETE FROM babel7022_parent2 WHERE id = 1
GO

SELECT COUNT(*) AS history_count FROM babel7022_history2
GO

-- TEST 3: ON UPDATE CASCADE - trigger should fire once with all 5 updated child rows
INSERT INTO babel7022_parent3 VALUES (1, 'old'), (2, 'new')
GO

INSERT INTO babel7022_child3 VALUES (1, 1, 'a'), (2, 1, 'b'), (3, 1, 'c'), (4, 1, 'd'), (5, 1, 'e')
GO

UPDATE babel7022_parent3 SET id = 10 WHERE id = 1
GO

SELECT COUNT(*) AS log_count FROM babel7022_update_log
GO

SELECT child_id, old_parent_id, new_parent_id FROM babel7022_update_log ORDER BY child_id
GO

-- TEST 4: Two triggers on same table - each should fire exactly once during CASCADE
INSERT INTO babel7022_parent4 SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
GO

INSERT INTO babel7022_child4 SELECT 1,1 UNION SELECT 2,2 UNION SELECT 3,3 UNION SELECT 4,4 UNION SELECT 5,5
GO

DELETE FROM babel7022_parent4
GO

SELECT 'trigger_a' AS trigger_name, COUNT(*) AS fire_count, SUM(cnt) AS total_rows FROM babel7022_audit4a
GO

SELECT 'trigger_b' AS trigger_name, COUNT(*) AS fire_count, SUM(cnt) AS total_rows FROM babel7022_audit4b
GO

-- TEST 5: Nested CASCADE (grandparent -> parent -> child) - validates multi-level FK chains
INSERT INTO babel7022_gp VALUES (1), (2)
GO

INSERT INTO babel7022_p VALUES (1, 1), (2, 1), (3, 2), (4, 2)
GO

INSERT INTO babel7022_c VALUES (1, 1), (2, 1), (3, 3), (4, 3)
GO

DELETE FROM babel7022_gp
GO

SELECT tbl, del_count FROM babel7022_gp_log ORDER BY tbl
GO

-- TEST 6: Direct DELETE without CASCADE - ensures normal trigger path is not regressed
INSERT INTO babel7022_standalone VALUES (1, 'a'), (2, 'b'), (3, 'c'), (4, 'd'), (5, 'e')
GO

DELETE FROM babel7022_standalone
GO

SELECT COUNT(*) AS log_count FROM babel7022_standalone_log
GO

-- TEST 7: INSERT trigger should not be affected by CASCADE DELETE on same table
INSERT INTO babel7022_parent7 VALUES (1), (2), (3)
GO

INSERT INTO babel7022_child7 VALUES (1, 1), (2, 2), (3, 3)
GO

SELECT COUNT(*) AS ins_log_count FROM babel7022_ins_log
GO

DELETE FROM babel7022_parent7
GO

SELECT COUNT(*) AS ins_log_count FROM babel7022_ins_log
GO

-- TEST 8: Regular UPDATE trigger (no CASCADE) - ensures composite trigger path still works
INSERT INTO babel7022_t8 VALUES (1, 10), (2, 20), (3, 30)
GO

UPDATE babel7022_t8 SET val = val + 100
GO

SELECT COUNT(*) AS log_count FROM babel7022_t8_log
GO

SELECT id, old_val, new_val FROM babel7022_t8_log ORDER BY id
GO

-- TEST 9: CASCADE DELETE when parent has no children - trigger still fires with empty deleted
-- [BABEL-7027]: SQL Server does not fire the trigger in this case (log_count would be 0).
-- Babelfish fires it with an empty deleted table.
INSERT INTO babel7022_parent9 VALUES (1), (2), (3)
GO

INSERT INTO babel7022_child9 VALUES (10, 2), (20, 3)
GO

DELETE FROM babel7022_parent9 WHERE id = 1
GO

SELECT * FROM babel7022_log9 ORDER BY cnt
GO

DELETE FROM babel7022_parent9 WHERE id = 2
GO

SELECT * FROM babel7022_log9 ORDER BY cnt
GO

-- TEST 10: CASCADE DELETE inside explicit transaction - trigger should fire correctly within txn
INSERT INTO babel7022_parent10 VALUES (1), (2), (3)
GO

INSERT INTO babel7022_child10 VALUES (1, 1), (2, 2), (3, 3)
GO

BEGIN TRANSACTION
GO

DELETE FROM babel7022_parent10
GO

SELECT COUNT(*) AS log_count FROM babel7022_log10
GO

COMMIT
GO

SELECT COUNT(*) AS log_count FROM babel7022_log10
GO

-- TEST 11: Separate DELETE statements should each fire trigger independently, no cross-bleed
INSERT INTO babel7022_parent11 VALUES (1), (2), (3)
GO

INSERT INTO babel7022_child11 VALUES (1, 1), (2, 1), (3, 2), (4, 2), (5, 3), (6, 3)
GO

DELETE FROM babel7022_parent11 WHERE id = 1
GO

DELETE FROM babel7022_parent11 WHERE id = 2
GO

DELETE FROM babel7022_parent11 WHERE id = 3
GO

SELECT firing_num, del_count FROM babel7022_log11 ORDER BY firing_num
GO

-- TEST 12a: CASCADE DELETE + ROLLBACK - trigger effects undone, rows restored
INSERT INTO babel7022_parent12 VALUES (1), (2), (3), (4), (5)
GO

INSERT INTO babel7022_child12 VALUES (1,1), (2,2), (3,3), (4,4), (5,5)
GO

BEGIN TRANSACTION
GO

DELETE FROM babel7022_parent12
GO

ROLLBACK TRANSACTION
GO

SELECT COUNT(*) AS log_count_after_rollback FROM babel7022_log12
GO

SELECT COUNT(*) AS parent_count_after_rollback FROM babel7022_parent12
GO

-- TEST 12b: CASCADE DELETE with SAVE TRANSACTION then COMMIT - trigger fires once
DELETE FROM babel7022_log12
GO

BEGIN TRANSACTION
GO

SAVE TRANSACTION sp1
GO

DELETE FROM babel7022_parent12
GO

COMMIT TRANSACTION
GO

SELECT COUNT(*) AS log_count_after_savepoint_commit FROM babel7022_log12
GO

-- TEST 12c: ROLLBACK TO SAVEPOINT - work before savepoint survives, work after undone
DELETE FROM babel7022_child12
GO

DELETE FROM babel7022_parent12
GO

DELETE FROM babel7022_log12
GO

INSERT INTO babel7022_parent12 VALUES (1), (2), (3), (4), (5)
GO

INSERT INTO babel7022_child12 VALUES (1,1), (2,2), (3,3), (4,4), (5,5)
GO

BEGIN TRANSACTION
GO

DELETE FROM babel7022_parent12 WHERE id IN (1, 2)
GO

SAVE TRANSACTION sp1
GO

DELETE FROM babel7022_parent12 WHERE id IN (3, 4, 5)
GO

ROLLBACK TRANSACTION sp1
GO

COMMIT TRANSACTION
GO

SELECT id, parent_id FROM babel7022_log12 ORDER BY id
GO

SELECT id FROM babel7022_parent12 ORDER BY id
GO

-- TEST 13a: trigger body with SAVE TRANSACTION - fires once per statement during CASCADE
INSERT INTO babel7022_parent13a VALUES (1), (2), (3), (4), (5)
GO

INSERT INTO babel7022_child13a VALUES (1,1), (2,2), (3,3), (4,4), (5,5)
GO

DELETE FROM babel7022_parent13a
GO

SELECT COUNT(*) AS savepoint_in_trigger_count FROM babel7022_history13a
GO

-- TEST 13b: savepoint + rollback to savepoint inside trigger - only post-savepoint insert undone
INSERT INTO babel7022_parent13b VALUES (1), (2), (3), (4), (5)
GO

INSERT INTO babel7022_child13b VALUES (1,1), (2,2), (3,3), (4,4), (5,5)
GO

DELETE FROM babel7022_parent13b
GO

SELECT parent_id, COUNT(*) AS cnt FROM babel7022_history13b GROUP BY parent_id ORDER BY parent_id
GO

-- TEST 13c: trigger body with BEGIN TRANSACTION / COMMIT - fires once per statement
INSERT INTO babel7022_parent13c VALUES (1), (2), (3), (4), (5)
GO

INSERT INTO babel7022_child13c VALUES (1,1), (2,2), (3,3), (4,4), (5,5)
GO

DELETE FROM babel7022_parent13c
GO

SELECT COUNT(*) AS begin_commit_in_trigger_count FROM babel7022_history13c
GO

-- TEST 13d: trigger body with full ROLLBACK - aborts the batch, everything rolled back
INSERT INTO babel7022_parent13d VALUES (1), (2), (3), (4), (5)
GO

INSERT INTO babel7022_child13d VALUES (1,1), (2,2), (3,3), (4,4), (5,5)
GO

DELETE FROM babel7022_parent13d
GO

SELECT COUNT(*) AS history_after_rollback FROM babel7022_history13d
GO

SELECT COUNT(*) AS parent_after_rollback FROM babel7022_parent13d
GO

-- TEST 14: Multi-row INSERT without cascade - trigger fires once seeing all rows
INSERT INTO babel7022_t14 VALUES (1,10), (2,20), (3,30), (4,40), (5,50)
GO

SELECT COUNT(*) AS fire_count, MAX(rows_seen) AS rows_seen_per_fire FROM babel7022_fire14
GO

-- TEST 15: Multi-row UPDATE without cascade - trigger fires once seeing all rows
INSERT INTO babel7022_t15 VALUES (1,10), (2,20), (3,30), (4,40), (5,50)
GO

UPDATE babel7022_t15 SET val = val + 1
GO

SELECT COUNT(*) AS fire_count, MAX(rows_seen) AS rows_seen_per_fire FROM babel7022_fire15
GO

-- TEST 16: Multi-row DELETE without cascade - trigger fires once seeing all rows
INSERT INTO babel7022_t16 VALUES (1,10), (2,20), (3,30), (4,40), (5,50)
GO

DELETE FROM babel7022_t16
GO

SELECT COUNT(*) AS fire_count, MAX(rows_seen) AS rows_seen_per_fire FROM babel7022_fire16
GO

-- TEST 17: Chained triggers - each trigger in the chain fires once
INSERT INTO babel7022_parent17 VALUES (1), (2), (3), (4), (5)
GO

INSERT INTO babel7022_child17 VALUES (1,1), (2,2), (3,3), (4,4), (5,5)
GO

DELETE FROM babel7022_parent17
GO

SELECT COUNT(*) AS audit_count FROM babel7022_audit17
GO

SELECT COUNT(*) AS audit_fire_count, MAX(rows_seen) AS rows_seen_per_fire FROM babel7022_audit17_fire
GO

-- TEST 18: ON DELETE SET NULL - deleting parents nulls children's FK via one UPDATE, trigger fires once
INSERT INTO babel7022_parent18 VALUES (1), (2), (3), (4), (5)
GO

INSERT INTO babel7022_child18 VALUES (1,1), (2,2), (3,3), (4,4), (5,5)
GO

DELETE FROM babel7022_parent18
GO

SELECT COUNT(*) AS fire_count, MAX(rows_seen) AS rows_seen_per_fire FROM babel7022_fire18
GO

SELECT COUNT(*) AS null_children FROM babel7022_child18 WHERE parent_id IS NULL
GO

-- TEST 19: ON DELETE SET DEFAULT - deleting parents sets children's FK to default via one UPDATE, trigger fires once
INSERT INTO babel7022_parent19 VALUES (1), (2), (3), (4), (5), (99)
GO

INSERT INTO babel7022_child19 VALUES (1,1), (2,2), (3,3), (4,4), (5,5)
GO

DELETE FROM babel7022_parent19 WHERE id IN (1, 2, 3, 4, 5)
GO

SELECT COUNT(*) AS fire_count, MAX(rows_seen) AS rows_seen_per_fire FROM babel7022_fire19
GO

SELECT COUNT(*) AS default_children FROM babel7022_child19 WHERE parent_id = 99
GO

-- TEST 20: THROW (batch-terminating) inside trigger during CASCADE - delete rolled back, error surfaces
INSERT INTO babel7022_parent20 VALUES (1), (2), (3)
GO

INSERT INTO babel7022_child20 VALUES (10,1), (20,2), (30,3)
GO

DELETE FROM babel7022_parent20 WHERE id = 1
GO

SELECT COUNT(*) AS parent_remaining FROM babel7022_parent20
GO

-- TEST 21: TRY/CATCH around a CASCADE whose trigger errors - error caught, batch continues
INSERT INTO babel7022_parent21 VALUES (1), (2), (3)
GO

INSERT INTO babel7022_child21 VALUES (10,1), (20,2), (30,3)
GO

BEGIN TRY
  DELETE FROM babel7022_parent21 WHERE id = 1
END TRY
BEGIN CATCH
  SELECT ERROR_NUMBER() AS err_number, ERROR_MESSAGE() AS err_message
END CATCH
GO

SELECT COUNT(*) AS parent_remaining FROM babel7022_parent21
GO

-- TEST 22: recovery after error - poison CASCADE aborts, then good CASCADE still fires exactly once
INSERT INTO babel7022_parent22p VALUES (1), (2)
GO

INSERT INTO babel7022_child22p VALUES (10,1), (20,2)
GO

INSERT INTO babel7022_parent22g VALUES (1), (2), (3), (4), (5)
GO

INSERT INTO babel7022_child22g VALUES (10,1), (20,2), (30,3), (40,4), (50,5)
GO

BEGIN TRY
  DELETE FROM babel7022_parent22p
END TRY
BEGIN CATCH
  SELECT ERROR_NUMBER() AS caught_err
END CATCH
GO

DELETE FROM babel7022_parent22g
GO

SELECT COUNT(*) AS poison_remaining FROM babel7022_parent22p
GO

SELECT COUNT(*) AS good_fire_count, MAX(rows_seen) AS rows_seen_per_fire FROM babel7022_fire22g
GO

-- TEST 23: runtime DML error (PK violation) inside trigger during CASCADE - delete rolled back
INSERT INTO babel7022_parent23 VALUES (1), (2), (3)
GO

INSERT INTO babel7022_child23 VALUES (10,1), (20,2), (30,3)
GO

INSERT INTO babel7022_audit23 VALUES (99)
GO

DELETE FROM babel7022_parent23 WHERE id = 1
GO

SELECT COUNT(*) AS parent_remaining FROM babel7022_parent23
GO

-- TEST 24: TRY/CATCH inside trigger body catches an error - transaction doomed, batch aborted, cascade rolled back (Msg 3616)
INSERT INTO babel7022_parent24 VALUES (1), (2), (3)
GO

INSERT INTO babel7022_child24 VALUES (10,1), (20,2), (30,3)
GO

DELETE FROM babel7022_parent24 WHERE id = 1
GO

SELECT COUNT(*) AS parent_remaining FROM babel7022_parent24
GO
