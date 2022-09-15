CREATE DATABASE sys_system_sql_modules_dep_vu_prepare_db1
GO

USE sys_system_sql_modules_dep_vu_prepare_db1
GO

CREATE PROCEDURE sys_system_sql_modules_dep_vu_prepare_p1 as 
    SELECT uses_ansi_nulls FROM sys.system_sql_modules WHERE object_id = OBJECT_ID('sys.fn_listextendedproperty')
GO

CREATE FUNCTION sys_system_sql_modules_dep_vu_prepare_f1()
RETURNS INT 
AS 
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.system_sql_modules WHERE object_id = OBJECT_ID('sys.fn_listextendedproperty'))
END
GO

CREATE VIEW sys_system_sql_modules_dep_vu_prepare_v1 AS
    SELECT uses_ansi_nulls FROM sys.system_sql_modules WHERE object_id = OBJECT_ID('sys.fn_listextendedproperty')
GO
