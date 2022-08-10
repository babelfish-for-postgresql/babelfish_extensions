-- dependent objects test for upgrade
CREATE VIEW sys_system_sql_modules_vu_dep_view AS
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
FROM sys.all_sql_modules
WHERE object_id = OBJECT_ID('sys.tables')
GO

CREATE PROC sys_system_sql_modules_vu_dep_proc AS
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
FROM sys.all_sql_modules
WHERE object_id = OBJECT_ID('sys.tables')
GO

CREATE FUNCTION sys_system_sql_modules_vu_dep_func()
RETURNS INT
BEGIN
RETURN (SELECT COUNT(*) FROM sys.all_sql_modules WHERE object_id = OBJECT_ID('sys.tables'))
END
GO
