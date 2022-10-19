EXEC sys_computed_columns_dep_vu_prepare_p1
GO

SELECT * FROM sys_computed_columns_dep_vu_prepare_f1()
GO

DROP VIEW sys_computed_columns_dep_vu_prepare_v1
GO

CREATE VIEW sys_computed_columns_dep_vu_prepare_v1 AS
    SELECT name FROM sys.computed_columns where name in ('scc_multiplied1')
GO

SELECT * FROM sys_computed_columns_dep_vu_prepare_v1
GO

