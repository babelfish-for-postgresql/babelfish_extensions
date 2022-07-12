DROP TABLE IF EXISTS sys_default_definitions
GO

CREATE TABLE sys_default_definitions (column_a INT, column_b INT)
GO

ALTER TABLE sys_default_definitions ADD CONSTRAINT DF_sdd_column_b DEFAULT 50 FOR column_b
GO