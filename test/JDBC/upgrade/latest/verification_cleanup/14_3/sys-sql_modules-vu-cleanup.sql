-- Cleanup
DROP PROC sys_sql_modules_vu_proc
GO

DROP TRIGGER sys_sql_modules_vu_trig
GO

DROP TABLE sys_sql_modules_vu_table1
GO

DROP TABLE sys_sql_modules_vu_table2
GO

DROP VIEW sys_sql_modules_vu_view
GO

DROP FUNCTION sys_sql_modules_vu_function
GO

USE sys_sql_modules_vu_db1
GO

DROP VIEW sys_sql_modules_vu_my_db_view
GO

USE master
GO

DROP DATABASE sys_sql_modules_vu_db1
GO

DROP VIEW sys_sql_modules_vu_dep_view
GO

DROP PROC sys_sql_modules_vu_dep_proc
GO

DROP FUNCTION sys_sql_modules_vu_dep_func
GO
