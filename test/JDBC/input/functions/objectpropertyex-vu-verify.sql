-- sla 650000
-- Check for correct case
SELECT CASE
    WHEN OBJECTPROPERTY(OBJECT_ID('objectpropertyex_ownerid_schema.objectpropertyex_ownerid_table'), 'OwnerId')  = (SELECT principal_id 
            FROM sys.database_principals
            WHERE name = CURRENT_USER)
        Then 'SUCCESS'
    ELSE
        'FAILED'
END
GO

-- Invalid property ID (should return NULL)
SELECT OBJECTPROPERTY(0, 'OwnerId')
GO

-- =============== BaseType ===============

-- Tests valid cases

SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_basetype_table'), 'BaseType')
GO

SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_basetype_view'), 'BaseType')
GO

SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_basetype_function'), 'BaseType')
GO

SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_basetype_proc'), 'BaseType')
GO

-- Tests invalid object
SELECT OBJECTPROPERTYEX(0, 'BaseType')
GO

-- =============== Special Input Cases ===============

-- Tests special input cases
SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_specialinput_table'), 'BASETYPE')
GO

SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_specialinput_table'), 'basetype')
GO

SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_specialinput_table'), 'BASETYPE       ')
GO

-- =============== NULL input handling ===============

SELECT OBJECTPROPERTYEX(NULL, 'BaseType')
GO

SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_basetype_table'), NULL)
GO

SELECT OBJECTPROPERTYEX(NULL, NULL)
GO

-- =============== BaseType - additional object types ===============

-- Trigger
SELECT OBJECTPROPERTYEX(
    (SELECT object_id FROM sys.triggers WHERE name = 'objectpropertyex_test_trigger'),
    'BaseType')
GO

-- Primary key constraint
SELECT OBJECTPROPERTYEX(
    (SELECT object_id FROM sys.key_constraints WHERE name = 'objectpropertyex_pk'),
    'BaseType')
GO

-- Foreign key constraint
SELECT OBJECTPROPERTYEX(
    (SELECT object_id FROM sys.foreign_keys WHERE name = 'objectpropertyex_fk'),
    'BaseType')
GO

-- Check constraint
SELECT OBJECTPROPERTYEX(
    (SELECT object_id FROM sys.check_constraints WHERE name LIKE '%objectpropertyex_constraint_table%' AND parent_column_id = (SELECT column_id FROM sys.columns WHERE name = 'c' AND object_id = OBJECT_ID('objectpropertyex_constraint_table'))),
    'BaseType')
GO

-- Default constraint
SELECT OBJECTPROPERTYEX(
    (SELECT object_id FROM sys.default_constraints WHERE parent_object_id = OBJECT_ID('objectpropertyex_constraint_table') AND parent_column_id = (SELECT column_id FROM sys.columns WHERE name = 'b' AND object_id = OBJECT_ID('objectpropertyex_constraint_table'))),
    'BaseType')
GO

-- Sequence
SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_test_seq'), 'BaseType')
GO

-- Inline table-valued function
SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_itvf'), 'BaseType')
GO

-- Multi-statement table-valued function
SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_tvf'), 'BaseType')
GO

-- =============== IsSchemaBound ===============

-- Schema-bound function should return 0 (hardcoded for non-view objects)
SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_schemabound_fn'), 'IsSchemaBound')
GO

-- Non-schema-bound function should return 0
SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_noschemabound_fn'), 'IsSchemaBound')
GO

-- View created with default weak_view_binding=false (strong-bound): returns 1
SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_basetype_view'), 'IsSchemaBound')
GO

-- View created with weak_view_binding=true (weak-bound, no SCHEMABINDING): returns 0
SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_weak_view'), 'IsSchemaBound')
GO

-- View created with weak_view_binding=true but WITH SCHEMABINDING: returns 1
SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_schemabound_view'), 'IsSchemaBound')
GO

-- Table - IsSchemaBound not applicable, should return NULL
SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_basetype_table'), 'IsSchemaBound')
GO

-- Stored procedure
SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_basetype_proc'), 'IsSchemaBound')
GO

-- =============== IsIndexed ===============

-- Table with index
SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_indexed_table'), 'IsIndexed')
GO

-- Table without index
SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_noindex_table'), 'IsIndexed')
GO

-- Non-table object - should return 0
SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_basetype_view'), 'IsIndexed')
GO

-- =============== IsDefaultCnst ===============

-- Default constraint
SELECT OBJECTPROPERTYEX(
    (SELECT object_id FROM sys.default_constraints WHERE parent_object_id = OBJECT_ID('objectpropertyex_default_table')),
    'IsDefaultCnst')
GO

-- Non-default object
SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_basetype_table'), 'IsDefaultCnst')
GO

-- =============== IsMSShipped ===============

-- User-created table should not be MS shipped
SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_notshipped_table'), 'IsMSShipped')
GO

-- System object should be MS shipped
SELECT OBJECTPROPERTYEX(OBJECT_ID('sys.objects'), 'IsMSShipped')
GO

-- =============== Type-checking properties ===============

-- IsTable
SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_basetype_table'), 'IsTable')
GO

SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_basetype_view'), 'IsTable')
GO

-- IsView
SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_basetype_view'), 'IsView')
GO

SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_basetype_table'), 'IsView')
GO

-- IsUserTable
SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_basetype_table'), 'IsUserTable')
GO

SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_basetype_view'), 'IsUserTable')
GO

-- IsProcedure
SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_basetype_proc'), 'IsProcedure')
GO

SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_basetype_table'), 'IsProcedure')
GO

-- IsScalarFunction
SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_basetype_function'), 'IsScalarFunction')
GO

SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_basetype_proc'), 'IsScalarFunction')
GO

-- IsTableFunction
SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_tvf'), 'IsTableFunction')
GO

SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_basetype_table'), 'IsTableFunction')
GO

-- IsInlineFunction
SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_itvf'), 'IsInlineFunction')
GO

SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_tvf'), 'IsInlineFunction')
GO

-- IsPrimaryKey
SELECT OBJECTPROPERTYEX(
    (SELECT object_id FROM sys.key_constraints WHERE name = 'objectpropertyex_pk'),
    'IsPrimaryKey')
GO

SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_basetype_table'), 'IsPrimaryKey')
GO

-- =============== ExecIsQuotedIdentOn / ExecIsAnsiNullsOn ===============

-- These return 1 for applicable objects (procs, functions, views, triggers)
SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_basetype_proc'), 'ExecIsQuotedIdentOn')
GO

SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_basetype_function'), 'ExecIsAnsiNullsOn')
GO

-- Not applicable to tables - should return NULL
SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_basetype_table'), 'ExecIsQuotedIdentOn')
GO

SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_basetype_table'), 'ExecIsAnsiNullsOn')
GO

-- =============== Cross-database scoping ===============

-- Object from another database should return NULL in current database context
USE objectpropertyex_otherdb
GO

-- Object from default database should not be visible here
SELECT OBJECTPROPERTYEX(OBJECT_ID('objectpropertyex_basetype_table'), 'BaseType')
GO

USE master
GO
