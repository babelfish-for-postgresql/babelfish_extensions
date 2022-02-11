DROP TABLE IF EXISTS sys_computed_columns
GO

CREATE TABLE sys_computed_columns ( 
  scc_first_number smallint,
  scc_second_number money,
  scc_multiplied AS scc_first_number * scc_second_number
)
GO

SELECT name FROM sys.computed_columns where name in ('scc_multiplied')
GO

SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.computed_columns');
GO

DROP TABLE IF EXISTS sys_computed_columns
GO
