-- sla 50000
-- NOTE: Some tests will be marked as "DISABLED DUE TO NON-UNIQUE OBJECT_ID"
-- This is because during MVU, items in pg_class an pg_proc could have the same OBJECT_ID
-- Some tests have no way of identification except for OBJECT_ID since definition will be missing
-- These will be tested in the regular JDBC test

-- DISABLED DUE TO NON-UNIQUE OBJECT_ID
-- Test for system function
-- SELECT
--     definition,
--     uses_ansi_nulls,
--     uses_quoted_identifier,
--     is_schema_bound,
--     uses_database_collation,
--     is_recompiled,
--     null_on_null_input,
--     execute_as_principal_id,
--     uses_native_compilation
-- FROM sys.system_sql_modules
-- WHERE object_id = OBJECT_ID('sys.fn_listextendedproperty')
-- GO

-- DISABLED DUE TO NON-UNIQUE OBJECT_ID
-- Test for system views
-- SELECT
--     definition,
--     uses_ansi_nulls,
--     uses_quoted_identifier,
--     is_schema_bound,
--     uses_database_collation,
--     is_recompiled,
--     null_on_null_input,
--     execute_as_principal_id,
--     uses_native_compilation
-- FROM sys.system_sql_modules
-- WHERE object_id = OBJECT_ID('sys.tables')
-- GO


-- Test for system proc
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
FROM sys.system_sql_modules
WHERE definition LIKE 'CREATE PROCEDURE sp_tables%'
GO

-- DISABLED DUE TO NON-UNIQUE OBJECT_ID
-- Test for system function written in c 
-- SELECT
--     definition,
--     uses_ansi_nulls,
--     uses_quoted_identifier,
--     is_schema_bound,
--     uses_database_collation,
--     is_recompiled,
--     null_on_null_input,
--     execute_as_principal_id,
--     uses_native_compilation
-- FROM sys.system_sql_modules
-- WHERE object_id = OBJECT_ID('sys.user_name')
-- GO
