-- Setup
CREATE DATABASE db1
GO

-- Test for system function
SELECT
    uses_ansi_nulls,
    uses_quoted_identifier,
    is_schema_bound,
    uses_database_collation,
    is_recompiled,
    null_on_null_input,
    execute_as_principal_id,
    uses_native_compilation
FROM sys.system_sql_modules
WHERE object_id = OBJECT_ID('sys.fn_listextendedproperty')
GO

-- Test for system views
SELECT
    uses_ansi_nulls,
    uses_quoted_identifier,
    is_schema_bound,
    uses_database_collation,
    is_recompiled,
    null_on_null_input,
    execute_as_principal_id,
    uses_native_compilation
FROM sys.system_sql_modules
WHERE object_id = OBJECT_ID('sys.tables')
GO

-- Test for system proc
SELECT
    uses_ansi_nulls,
    uses_quoted_identifier,
    is_schema_bound,
    uses_database_collation,
    is_recompiled,
    null_on_null_input,
    execute_as_principal_id,
    uses_native_compilation
FROM sys.system_sql_modules
WHERE object_id = OBJECT_ID('sys.sp_tables')
GO

-- Cleanup
USE master
GO

DROP DATABASE db1
GO