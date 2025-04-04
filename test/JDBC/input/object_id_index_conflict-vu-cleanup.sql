-- Index cleanup
DROP INDEX IF EXISTS dbo.object_id_conflict_t.object_id_idx_name;
GO

DROP INDEX IF EXISTS dbo.object_id_conflict_parent_t.object_id_idx_parent_id;
GO

-- Constraint cleanup
ALTER TABLE object_id_conflict_t DROP CONSTRAINT IF EXISTS pk_id;
GO

ALTER TABLE object_id_conflict_t DROP CONSTRAINT IF EXISTS fk_constraint;
GO

ALTER TABLE object_id_conflict_t DROP CONSTRAINT IF EXISTS chk_age;
GO

ALTER TABLE object_id_conflict_t DROP CONSTRAINT IF EXISTS unq_name;
GO

-- Table cleanup
DROP TABLE IF EXISTS object_id_conflict_parent_t;
GO

DROP TABLE IF EXISTS object_id_conflict_t;
GO