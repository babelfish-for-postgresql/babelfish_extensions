DROP TABLE IF EXISTS sys_default_constraints_dep_vu_prepare_t1
GO

CREATE TABLE sys_default_constraints_dep_vu_prepare_t1 (column_a INT, column_b INT)
GO

ALTER TABLE sys_default_constraints_dep_vu_prepare_t1 ADD CONSTRAINT DF_sdd_column_b DEFAULT 50 FOR column_b
GO

CREATE PROCEDURE sys_default_constraints_dep_vu_prepare_p1 AS 
    SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.default_constraints')
GO

CREATE FUNCTION sys_default_constraints_dep_vu_prepare_f1()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.default_constraints'));
END
GO

CREATE VIEW sys_default_constraints_dep_vu_prepare_v1 AS
    SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.default_constraints')
GO
