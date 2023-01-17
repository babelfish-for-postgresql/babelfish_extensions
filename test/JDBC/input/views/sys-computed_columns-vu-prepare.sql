DROP TABLE IF EXISTS sys_computed_columns_vu_prepare_t1
GO

CREATE TABLE sys_computed_columns_vu_prepare_t1 ( 
  scc_first_number smallint,
  scc_second_number money,
  scc_multiplied AS scc_first_number * scc_second_number
)
GO
