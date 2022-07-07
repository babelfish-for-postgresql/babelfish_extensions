USE db1
GO

-- =============== OwnerId ===============

-- Check for correct case
SELECT CASE
    WHEN OBJECTPROPERTY(OBJECT_ID('ownerid_schema.ownerid_table'), 'OwnerId')  = (SELECT principal_id 
            FROM sys.database_principals
            WHERE name = CURRENT_USER)
        Then 'SUCCESS'
    ELSE
        'FAILED'
END
GO

-- Check for system object. Should return 10 since that's the owner ID. 
SELECT OBJECTPROPERTY(OBJECT_ID('sys.objects'), 'OwnerId')
GO

-- Invalid property ID (should return NULL)
SELECT OBJECTPROPERTY(0, 'OwnerId')
GO

-- Check for mix-cased property
SELECT OBJECTPROPERTY(OBJECT_ID('sys.objects'), 'oWnEriD')
GO

-- Check for trailing white spaces
SELECT OBJECTPROPERTY(OBJECT_ID('sys.objects'), 'OwnerId     ')
GO

-- Check for trailing white spaces and mixed case
SELECT OBJECTPROPERTY(OBJECT_ID('sys.objects'), 'oWnEriD     ')
GO

-- =============== IsDefaultCnst ===============

-- Check for correct cases (should return 1)
SELECT OBJECTPROPERTY(ct.object_id, 'isdefaultcnst') 
from sys.default_constraints ct
where parent_object_id = OBJECT_ID('isdefaultcnst_table')
GO

SELECT OBJECTPROPERTY(ct.object_id, 'isdefaultcnst') 
from sys.default_constraints ct
where parent_object_id = OBJECT_ID('isdefaultcnst_table2')
GO

-- Check for object_id that exists, but not an index (should return 0)
SELECT OBJECTPROPERTY(OBJECT_ID('isdefaultcnst_table'), 'IsDefaultCnst')
GO

-- Check for invalid object_id (should return NULL)
SELECT OBJECTPROPERTY(0, 'IsDefaultCnst')
GO

-- =============== ExecIsQuotedIdentOn ===============

-- Does not function properly due to sys.sql_modules not recording the correct settings

-- Currently does not work due to hardcoded value in sys.sql_modules (should be 0)
SELECT OBJECTPROPERTY(OBJECT_ID('execisquotedident_proc_off'), 'ExecIsQuotedIdentOn') 
GO

SELECT OBJECTPROPERTY(OBJECT_ID('execisquotedident_proc_on'), 'ExecIsQuotedIdentOn')
GO

-- Check for object_id that exists, but not a proc, view, function, or sproc (should return NULL)
SELECT OBJECTPROPERTY(OBJECT_ID('execisquotedident_table'), 'ExecIsQuotedIdentOn')
GO

-- Check for invalid object_id (should return NULL)
SELECT OBJECTPROPERTY(0, 'ExecIsQuotedIdentOn')
GO

-- =============== IsMSShipped ===============

-- Test for object that exists but isn't ms_shipped
SELECT OBJECTPROPERTY(OBJECT_ID('is_ms_shipped_table'), 'IsMSShipped')
GO

-- Test for object that is ms_shipped
SELECT OBJECTPROPERTY(OBJECT_ID('sys.sp_tables'), 'IsMSShipped')
GO

-- Test for invalid object
SELECT OBJECTPROPERTY(0, 'IsMSShipped')
GO

-- =============== TableFullTextPopulateStatus ===============

-- Test with table object
SELECT OBJECTPROPERTY(OBJECT_ID('tablefulltextpopulatestatus_table'), 'TableFullTextPopulateStatus')
GO

-- Test with non-table object
SELECT OBJECTPROPERTY(OBJECT_ID('tablefulltextpopulatestatus_proc'), 'TableFullTextPopulateStatus')
GO

-- Test with invalid object id
SELECT OBJECTPROPERTY(0, 'TableFullTextPopulateStatus')
GO

-- =============== TableHasVarDecimalStorageFormat ===============

-- Test with table object
SELECT OBJECTPROPERTY(OBJECT_ID('TableHasVarDecimalStorageFormat_table'), 'TableHasVarDecimalStorageFormat')
GO

-- Test with non-table object
SELECT OBJECTPROPERTY(OBJECT_ID('TableHasVarDecimalStorageFormat_proc'), 'TableHasVarDecimalStorageFormat')
GO

-- Test with invalid object id
SELECT OBJECTPROPERTY(0, 'TableHasVarDecimalStorageFormat')
GO

-- =============== IsSchemaBound ===============

-- Test when object is not schema bound 
SELECT OBJECTPROPERTY(OBJECT_ID('IsSchemaBound_function_false'), 'IsSchemaBound')
GO

-- Test when object is schema bound (Currently does not work due to hardcoded value in sys.sql_modules, should return 1)
SELECT OBJECTPROPERTY(OBJECT_ID('IsSchemaBound_function_true'), 'IsSchemaBound')
GO

-- Test with object that doesn't have schema bound settings
SELECT OBJECTPROPERTY(OBJECT_ID('IsSchemaBound_table'), 'IsSchemaBound')
GO

-- Test with invalid object id
SELECT OBJECTPROPERTY(0, 'IsSchemaBound')
GO

-- =============== ExecIsAnsiNullsOn ===============

-- Currently does not work due to hardcoded value in sys.sql_modules

-- Tests when object is created with ansi nulls off and ansi nulls on

-- Currently does not work due to hardcoded value in sys.sql_modules (should return 0)
SELECT OBJECTPROPERTY(OBJECT_ID('ansi_nulls_off_proc'), 'ExecIsAnsiNullsOn')
GO

SELECT OBJECTPROPERTY(OBJECT_ID('ansi_nulls_on_proc'), 'ExecIsAnsiNullsOn')
GO

-- Test with invalid object id
SELECT OBJECTPROPERTY(0, 'ExecIsAnsiNullsOn')
GO

-- Check for object_id that exists, but not a proc, view, function, or sproc (should return NULL)
SELECT OBJECTPROPERTY(OBJECT_ID('ansi_nulls_on_table'), 'ExecIsAnsiNullsOn')
GO

-- Check for invalid object_id (should return NULL)
SELECT OBJECTPROPERTY(0, 'ExecIsAnsiNullsOn')
GO

-- =============== IsDeterministic ===============

-- Currently does not work since INFORMATION_SCHEMA.ROUTINES does not evaluate if a function is deterministic

-- Tests for a deterministic function (Currently does not work, should return 1)
SELECT OBJECTPROPERTY(OBJECT_ID('IsDeterministic_function_yes'), 'IsDeterministic')
GO

-- Tests for a non-deterministic function
SELECT OBJECTPROPERTY(OBJECT_ID('IsDeterministic_function_yes'), 'IsDeterministic')
GO

-- Tests for an object that is not a function
SELECT OBJECTPROPERTY(OBJECT_ID('IsDeterministic_table'), 'IsDeterministic')
GO

-- Tests for a non-valid object
SELECT OBJECTPROPERTY(0, 'IsDeterministic')
GO

-- =============== IsProcedure ===============

-- Test for success
SELECT OBJECTPROPERTY(OBJECT_ID('IsProcedure_proc'), 'IsProcedure')
GO

-- Test for failure 
SELECT OBJECTPROPERTY(OBJECT_ID('IsProcedure_table'), 'IsProcedure')
GO

-- Test for invalid object
SELECT OBJECTPROPERTY(0, 'IsProcedure')
GO

-- =============== IsTable ===============

-- Test for correct case
SELECT OBJECTPROPERTY(OBJECT_ID('IsTable_table'), 'IsTable')
GO

-- Test for incorrect case
SELECT OBJECTPROPERTY(OBJECT_ID('IsTable_proc'), 'IsTable')
GO

-- Test for invalid object
SELECT OBJECTPROPERTY(0, 'IsTable')
GO

-- =============== IsView ===============

-- Test for correct case
SELECT OBJECTPROPERTY(OBJECT_ID('IsView_view'), 'IsView')
GO

-- Test for incorrect case
SELECT OBJECTPROPERTY(OBJECT_ID('IsView_table'), 'IsView')
GO

-- Test for invalid object
SELECT OBJECTPROPERTY(0, 'IsView')
GO

-- =============== IsUserTable ===============

-- Test for correct case
SELECT OBJECTPROPERTY(OBJECT_ID('IsUserTable_table'), 'IsUserTable')
GO

-- Test for incorrect case
SELECT OBJECTPROPERTY(OBJECT_ID('IsUserTable_view'), 'IsUserTable')
GO

-- Test for invalid object
SELECT OBJECTPROPERTY(0, 'IsUserTable')
GO

-- =============== IsTableFunction ===============
-- NOTE: Currently will return 0 since sys.all_objects does not identify objects of type TF (BABELFISH-483)

-- Test for valid table function (currently incorrect from note above, should return 1)
SELECT OBJECTPROPERTY(OBJECT_ID('IsTableFunction_tablefunction'), 'IsTableFunction')
GO

-- Test for valid inline table function (currently incorrect from note above, should return 1)
SELECT OBJECTPROPERTY(OBJECT_ID('IsTableFunction_inlinetablefunction'), 'IsTableFunction')
GO

-- Test for incorrect case
SELECT OBJECTPROPERTY(OBJECT_ID('IsTableFunction_function'), 'IsTableFunction')
GO

-- Test for invalid object
SELECT OBJECTPROPERTY(0, 'IsTableFunction')
GO

-- =============== IsInlineFunction ===============
-- NOTE: Currently will return 0 since BBF cannot currently identify if a function is inline or not

-- Test for correct case (currently incorrect from note above, should return 1)
SELECT OBJECTPROPERTY(OBJECT_ID('IsInlineFunction_tablefunction'), 'IsInlineFunction')
GO

-- Test for incorrect case
SELECT OBJECTPROPERTY(OBJECT_ID('IsInlineFunction_function'), 'IsInlineFunction')
GO

-- Test for invalid object
SELECT OBJECTPROPERTY(0, 'IsInlineFunction')
GO

-- =============== IsScalarFunction ===============

-- Test for correct case
SELECT OBJECTPROPERTY(OBJECT_ID('IsScalarFunction_function'), 'IsScalarFunction')
GO

-- Test for incorrect case
SELECT OBJECTPROPERTY(OBJECT_ID('IsScalarFunction_table'), 'IsScalarFunction')
GO

-- Test for invalid object
SELECT OBJECTPROPERTY(0, 'IsScalarFunction')
GO

-- =============== IsPrimaryKey ===============

-- Test for correct case
SELECT OBJECTPROPERTY((SELECT TOP(1) object_id FROM sys.all_objects where name like 'pk_isprimarykey%' ), 'IsPrimaryKey')
GO

-- Test for incorrect case
SELECT OBJECTPROPERTY(OBJECT_ID('IsPrimaryKey_table'), 'IsPrimaryKey')
GO

-- Test for invalid object
SELECT OBJECTPROPERTY(0, 'IsPrimaryKey')
GO

-- =============== IsIndexed ===============

-- Test for correct case
SELECT OBJECTPROPERTY(OBJECT_ID('IsIndexed_table'), 'IsIndexed')
GO

-- Test for incorrect case
SELECT OBJECTPROPERTY(OBJECT_ID('IsIndexed_nonindexed_table'), 'IsIndexed')
GO

-- Test for invalid object
SELECT OBJECTPROPERTY(0, 'IsIndexed')
GO

-- =============== IsDefault ===============
-- NOTE: Defaults are currently not supported so will return 0

-- Test for valid object
SELECT OBJECTPROPERTY(OBJECT_ID('IsDefault_table'), 'IsDefault')
GO

-- Test for invalid object
SELECT OBJECTPROPERTY(0, 'IsDefault')
GO

-- =============== IsRule ===============
-- NOTE: Rules are currently not supported so will return 0

-- Test for valid object
SELECT OBJECTPROPERTY(OBJECT_ID('IsRule_table'), 'IsRule')
GO

-- Test for invalid object
SELECT OBJECTPROPERTY(0, 'IsRule')
GO

-- =============== IsTrigger ===============
-- Test for correct case
SELECT OBJECTPROPERTY(OBJECT_ID('IsTrigger_trigger', 'TR'), 'IsTrigger')
GO

-- Test for incorrect case
SELECT OBJECTPROPERTY(OBJECT_ID('IsTrigger_table', 'TR'), 'IsTrigger')
GO

-- Test for invalid object
SELECT OBJECTPROPERTY(0, 'IsTrigger')
GO