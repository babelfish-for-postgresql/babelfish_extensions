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

CREATE TRIGGER babel7022_child_del_trg
  ON babel7022_child
  AFTER DELETE
AS
BEGIN
  SET NOCOUNT ON;
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
