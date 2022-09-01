DROP TABLE IF EXISTS sys_computed_columns_dep_vu_prepare_t1
GO

CREATE TABLE sys_computed_columns_dep_vu_prepare_t1 ( 
  scc_first_number smallint,
  scc_second_number money,
  scc_multiplied AS scc_first_number * scc_second_number
)
GO

CREATE PROCEDURE sys_computed_columns_dep_vu_prepare_p1 AS
    SELECT name FROM sys.computed_columns where name in ('scc_multiplied')
GO

CREATE FUNCTION sys_computed_columns_dep_vu_prepare_f1()
RETURNS INT 
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.computed_columns'))
END
GO

CREATE VIEW sys_computed_columns_dep_vu_prepare_v1 AS
    SELECT name FROM sys.computed_columns where name in ('scc_multiplied')
GO
