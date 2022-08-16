DROP TABLE IF EXISTS sys_default_constraints_vu_prepare_t
GO

CREATE TABLE sys_default_constraints_vu_prepare_t (column_a INT, column_b INT)
GO

ALTER TABLE sys_default_constraints_vu_prepare_t ADD CONSTRAINT DF_sdd_column_b DEFAULT 50 FOR column_b
GO