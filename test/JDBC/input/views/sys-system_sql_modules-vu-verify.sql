-- sla 75000
-- Test for system function
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
WHERE object_id = OBJECT_ID('sys.fn_listextendedproperty')
GO

-- Test for system views
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
WHERE object_id = OBJECT_ID('sys.tables')
GO

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
WHERE definition LIKE 'CREATE PROCEDURE sp_columns_managed%'
GO

-- Test for system function written in c 
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
WHERE object_id = OBJECT_ID('sys.user_name')
GO
