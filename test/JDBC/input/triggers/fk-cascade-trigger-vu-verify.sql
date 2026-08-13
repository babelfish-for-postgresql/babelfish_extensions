-- TEST 1: Basic CASCADE DELETE - trigger should fire once seeing all 5 deleted rows, not 5 times
INSERT INTO babel7022_parent SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
GO

INSERT INTO babel7022_child (id, parent_id) SELECT 1,1 UNION SELECT 2,2 UNION SELECT 3,3 UNION SELECT 4,4 UNION SELECT 5,5
GO

DELETE FROM babel7022_parent
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
-- TODO: SQL Server does not fire the trigger in this case (log_count would be 0).
-- Babelfish fires it with an empty deleted table. This is a separate compatibility issue.
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
