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
-- WHERE definition LIKE 'CREATE PROCEDURE sp_helpdbfixedrole%'
-- GO

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

-- Test for linked server procedures
SELECT
    o.name,
    s.definition,
    s.uses_ansi_nulls,
    s.uses_quoted_identifier,
    s.is_schema_bound,
    s.uses_database_collation,
    s.is_recompiled,
    s.null_on_null_input,
    s.execute_as_principal_id,
    s.uses_native_compilation
FROM sys.objects o
LEFT JOIN sys.system_sql_modules s ON o.object_id = s.object_id
WHERE o.name IN ('sp_addlinkedserver', 'sp_addlinkedsrvlogin', 'sp_dropserver', 'sp_droplinkedsrvlogin')
ORDER BY o.name
GO
