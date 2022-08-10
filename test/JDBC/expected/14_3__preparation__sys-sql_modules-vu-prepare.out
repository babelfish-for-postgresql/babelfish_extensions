-- Setup
CREATE DATABASE sys_sql_modules_vu_db1
GO

USE sys_sql_modules_vu_db1
GO

CREATE VIEW sys_sql_modules_vu_my_db_view AS -- This view should not be seen as we will be using a different database for the test
SELECT 1 as c
GO

USE master
GO

CREATE TABLE sys_sql_modules_vu_table1(a int)
GO

CREATE TABLE sys_sql_modules_vu_table2(a int)
GO

CREATE TRIGGER sys_sql_modules_vu_trig ON sys_sql_modules_vu_table2 INSTEAD OF INSERT
AS
BEGIN
SELECT * FROM sys_sql_modules_vu_table1;
END
GO

CREATE VIEW sys_sql_modules_vu_view AS
SELECT 1 as c
GO

CREATE FUNCTION sys_sql_modules_vu_function() 
RETURNS INT
AS 
BEGIN
    RETURN 1;
END
GO

CREATE PROC sys_sql_modules_vu_proc AS
SELECT 1 as c
GO

-- dependent objects test for upgrade
CREATE VIEW sys_sql_modules_vu_dep_view AS
SELECT
    definition,
    uses_ansi_nulls,
    uses_quoted_identifier,
    is_schema_bound,
    uses_database_collation,
    is_recompiled,
    null_on_null_input,
    execute_as_principal_id,
    uses_native_compilation
FROM sys.sql_modules
WHERE object_id = OBJECT_ID('sys_sql_modules_vu_view')
GO

CREATE PROC sys_sql_modules_vu_dep_proc AS
SELECT
    definition,
    uses_ansi_nulls,
    uses_quoted_identifier,
    is_schema_bound,
    uses_database_collation,
    is_recompiled,
    null_on_null_input,
    execute_as_principal_id,
    uses_native_compilation
FROM sys.sql_modules
WHERE object_id = OBJECT_ID('sys_sql_modules_vu_view')
GO

CREATE FUNCTION sys_sql_modules_vu_dep_func()
RETURNS INT
BEGIN
RETURN (SELECT COUNT(*) FROM sys.sql_modules WHERE object_id = OBJECT_ID('sys_sql_modules_vu_view'))
END
GO
