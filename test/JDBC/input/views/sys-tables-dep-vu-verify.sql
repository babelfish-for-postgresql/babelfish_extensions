USE sys_tables_dep_vu_prepare_db1
GO

EXEC sys_tables_dep_vu_prepare_p1
GO

SELECT * FROM sys_tables_dep_vu_prepare_f1()
GO

SELECT * FROM sys_tables_dep_vu_prepare_view1
GO
