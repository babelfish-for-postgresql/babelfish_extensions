DROP TABLE IF EXISTS sys_default_definitions
GO

CREATE TABLE sys_default_definitions (column_a INT, column_b INT)
GO

ALTER TABLE sys_default_definitions ADD CONSTRAINT DF_sdd_column_b DEFAULT 50 FOR column_b
GO

SELECT definition FROM sys.default_constraints where name LIKE '%sys_default_definitions%'
GO

SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.default_constraints');
GO

DROP TABLE IF EXISTS sys_default_definitions
GO
