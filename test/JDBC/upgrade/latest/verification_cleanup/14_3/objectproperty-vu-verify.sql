-- =============== OwnerId ===============

-- Setup
CREATE SCHEMA objectproperty_vu_prepare_ownerid_schema
GO

CREATE TABLE objectproperty_vu_prepare_ownerid_schema.objectproperty_vu_prepare_ownerid_table(a int) 
GO

-- Check for correct case
SELECT CASE
    WHEN OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_ownerid_schema.objectproperty_vu_prepare_ownerid_table'), 'OwnerId')  = (SELECT principal_id 
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

-- Cleanup
DROP TABLE objectproperty_vu_prepare_ownerid_schema.objectproperty_vu_prepare_ownerid_table
GO

DROP SCHEMA objectproperty_vu_prepare_ownerid_schema
GO
-- =============== IsDefaultCnst ===============

-- Setup
CREATE TABLE objectproperty_vu_prepare_isdefaultcnst_table(a int DEFAULT 10)
GO

CREATE TABLE objectproperty_vu_prepare_isdefaultcnst_table2(a int DEFAULT 10, b int DEFAULT 20)
GO

-- Check for correct cases (should return 1)
SELECT OBJECTPROPERTY(ct.object_id, 'isdefaultcnst') 
from sys.default_constraints ct
where parent_object_id = OBJECT_ID('objectproperty_vu_prepare_isdefaultcnst_table')
GO

SELECT OBJECTPROPERTY(ct.object_id, 'isdefaultcnst') 
from sys.default_constraints ct
where parent_object_id = OBJECT_ID('objectproperty_vu_prepare_isdefaultcnst_table2')
GO

-- Check for object_id that exists, but not an index (should return 0)
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_isdefaultcnst_table'), 'IsDefaultCnst')
GO

-- Check for invalid object_id (should return NULL)
SELECT OBJECTPROPERTY(0, 'IsDefaultCnst')
GO

-- Cleanup
DROP TABLE objectproperty_vu_prepare_isdefaultcnst_table
GO

DROP TABLE objectproperty_vu_prepare_isdefaultcnst_table2
GO

-- =============== ExecIsQuotedIdentOn ===============

-- Does not function properly due to sys.sql_modules not recording the correct settings

-- Setup
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROC objectproperty_vu_prepare_execisquotedident_proc_off
AS
RETURN 1
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROC objectproperty_vu_prepare_execisquotedident_proc_on
AS
RETURN 1
GO

CREATE TABLE objectproperty_vu_prepare_execisquotedident_table(a int)
GO

-- Currently does not work due to hardcoded value in sys.sql_modules (should be 0)
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_execisquotedident_proc_off'), 'ExecIsQuotedIdentOn') 
GO

SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_execisquotedident_proc_on'), 'ExecIsQuotedIdentOn')
GO

-- Check for object_id that exists, but not a proc, view, function, or sproc (should return NULL)
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_execisquotedident_table'), 'ExecIsQuotedIdentOn')
GO

-- Check for invalid object_id (should return NULL)
SELECT OBJECTPROPERTY(0, 'ExecIsQuotedIdentOn')
GO

-- Cleanup
DROP PROC objectproperty_vu_prepare_execisquotedident_proc_on
GO
DROP PROC objectproperty_vu_prepare_execisquotedident_proc_off
GO
DROP TABLE objectproperty_vu_prepare_execisquotedident_table
GO

-- =============== IsMSShipped ===============

-- Setup
CREATE TABLE objectproperty_vu_prepare_is_ms_shipped_table(a int)
GO

-- Test for object that exists but isn't ms_shipped
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_is_ms_shipped_table'), 'IsMSShipped')
GO

-- Test for object that is ms_shipped
SELECT OBJECTPROPERTY(OBJECT_ID('sys.sp_tables'), 'IsMSShipped')
GO

-- Test for invalid object
SELECT OBJECTPROPERTY(0, 'IsMSShipped')
GO

-- Cleanup
DROP TABLE objectproperty_vu_prepare_is_ms_shipped_table
GO

-- =============== TableFullTextPopulateStatus ===============

-- Setup
CREATE TABLE objectproperty_vu_prepare_tablefulltextpopulatestatus_table(a int)
GO

CREATE PROC objectproperty_vu_prepare_tablefulltextpopulatestatus_proc
AS
RETURN 1
GO

-- Test with table object
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_tablefulltextpopulatestatus_table'), 'TableFullTextPopulateStatus')
GO

-- Test with non-table object
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_tablefulltextpopulatestatus_proc'), 'TableFullTextPopulateStatus')
GO

-- Test with invalid object id
SELECT OBJECTPROPERTY(0, 'TableFullTextPopulateStatus')
GO

-- Cleanup
DROP TABLE objectproperty_vu_prepare_tablefulltextpopulatestatus_table
GO

DROP PROC objectproperty_vu_prepare_tablefulltextpopulatestatus_proc
GO

-- =============== TableHasVarDecimalStorageFormat ===============

-- Setup
CREATE TABLE objectproperty_vu_prepare_TableHasVarDecimalStorageFormat_table(a int)
GO

CREATE proc objectproperty_vu_prepare_TableHasVarDecimalStorageFormat_proc
AS
RETURN 1
GO

-- Test with table object
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_TableHasVarDecimalStorageFormat_table'), 'TableHasVarDecimalStorageFormat')
GO

-- Test with non-table object
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_TableHasVarDecimalStorageFormat_proc'), 'TableHasVarDecimalStorageFormat')
GO

-- Test with invalid object id
SELECT OBJECTPROPERTY(0, 'TableHasVarDecimalStorageFormat')
GO

-- Cleanup
DROP TABLE objectproperty_vu_prepare_TableHasVarDecimalStorageFormat_table
GO

DROP PROC objectproperty_vu_prepare_TableHasVarDecimalStorageFormat_proc
GO

-- =============== IsSchemaBound ===============

-- Currently does not work due to hardcoded value in sys.sql_modules
-- Setup
CREATE FUNCTION objectproperty_vu_prepare_IsSchemaBound_function_false()
RETURNS int
BEGIN
    return 1
END
GO

CREATE FUNCTION objectproperty_vu_prepare_IsSchemaBound_function_true()
RETURNS int
WITH SCHEMABINDING
BEGIN
    return 1
END
GO

CREATE TABLE objectproperty_vu_prepare_IsSchemaBound_table(a int)
GO

-- Test when object is not schema bound 
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_IsSchemaBound_function_false'), 'IsSchemaBound')
GO

-- Test when object is schema bound (Currently does not work due to hardcoded value in sys.sql_modules, should return 1)
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_IsSchemaBound_function_true'), 'IsSchemaBound')
GO

-- Test with object that doesn't have schema bound settings
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_IsSchemaBound_table'), 'IsSchemaBound')
GO

-- Test with invalid object id
SELECT OBJECTPROPERTY(0, 'IsSchemaBound')
GO

-- Cleanup
DROP TABLE objectproperty_vu_prepare_IsSchemaBound_table
GO

DROP FUNCTION objectproperty_vu_prepare_IsSchemaBound_function_false
GO

DROP FUNCTION objectproperty_vu_prepare_IsSchemaBound_function_true
GO

-- =============== ExecIsAnsiNullsOn ===============

-- Currently does not work due to hardcoded value in sys.sql_modules
-- Setup
SET ANSI_NULLS OFF
GO

CREATE PROC objectproperty_vu_prepare_ansi_nulls_off_proc
AS
SELECT CASE WHEN NULL = NULL then 1 else 0 end
GO

SET ANSI_NULLS ON
GO

CREATE PROC objectproperty_vu_prepare_ansi_nulls_on_proc
AS
SELECT CASE WHEN NULL = NULL then 1 else 0 end
GO

CREATE TABLE objectproperty_vu_prepare_ansi_nulls_on_table(a int)
GO

-- Tests when object is created with ansi nulls off and ansi nulls on

-- Currently does not work due to hardcoded value in sys.sql_modules (should return 0)
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_ansi_nulls_off_proc'), 'ExecIsAnsiNullsOn')
GO

SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_ansi_nulls_on_proc'), 'ExecIsAnsiNullsOn')
GO

-- Test with invalid object id
SELECT OBJECTPROPERTY(0, 'ExecIsAnsiNullsOn')
GO

-- Check for object_id that exists, but not a proc, view, function, or sproc (should return NULL)
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_ansi_nulls_on_table'), 'ExecIsAnsiNullsOn')
GO

-- Check for invalid object_id (should return NULL)
SELECT OBJECTPROPERTY(0, 'ExecIsAnsiNullsOn')
GO

-- Cleanup
DROP PROC objectproperty_vu_prepare_ansi_nulls_off_proc
GO

DROP PROC objectproperty_vu_prepare_ansi_nulls_on_proc
GO

DROP TABLE objectproperty_vu_prepare_ansi_nulls_on_table
GO

-- =============== IsDeterministic ===============

-- Currently does not work since INFORMATION_SCHEMA.ROUTINES does not evaluate if a function is deterministic
-- Setup
CREATE FUNCTION objectproperty_vu_prepare_IsDeterministic_function_yes()
RETURNS int
WITH SCHEMABINDING
BEGIN
    return 1;
END
GO

CREATE FUNCTION objectproperty_vu_prepare_IsDeterministic_function_no()
RETURNS sys.datetime
WITH SCHEMABINDING
BEGIN
    return GETDATE();
END
GO

CREATE TABLE objectproperty_vu_prepare_IsDeterministic_table(a int)
GO

-- Tests for a deterministic function (Currently does not work, should return 1)
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_IsDeterministic_function_yes'), 'IsDeterministic')
GO

-- Tests for a non-deterministic function
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_IsDeterministic_function_yes'), 'IsDeterministic')
GO

-- Tests for an object that is not a function
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_IsDeterministic_table'), 'IsDeterministic')
GO

-- Tests for a non-valid object
SELECT OBJECTPROPERTY(0, 'IsDeterministic')
GO

-- Cleanup

DROP FUNCTION objectproperty_vu_prepare_IsDeterministic_function_no
GO

DROP FUNCTION objectproperty_vu_prepare_IsDeterministic_function_yes
GO

DROP TABLE objectproperty_vu_prepare_IsDeterministic_table
GO

-- =============== IsProcedure ===============
-- Setup
CREATE PROC objectproperty_vu_prepare_IsProcedure_proc AS
SELECT 1
GO

CREATE TABLE objectproperty_vu_prepare_IsProcedure_table(a int)
GO

-- Test for success
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_IsProcedure_proc'), 'IsProcedure')
GO

-- Test for failure 
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_IsProcedure_table'), 'IsProcedure')
GO

-- Test for invalid object
SELECT OBJECTPROPERTY(0, 'IsProcedure')
GO

-- Cleanup
DROP PROC objectproperty_vu_prepare_IsProcedure_proc
GO

DROP TABLE objectproperty_vu_prepare_IsProcedure_table
GO

-- =============== IsTable ===============
-- Setup
CREATE TABLE objectproperty_vu_prepare_IsTable_table(a int)
GO

CREATE PROC objectproperty_vu_prepare_IsTable_proc AS
SELECT 1
GO

-- Test for correct case
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_IsTable_table'), 'IsTable')
GO

-- Test for incorrect case
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_IsTable_proc'), 'IsTable')
GO

-- Test for invalid object
SELECT OBJECTPROPERTY(0, 'IsTable')
GO

-- Cleanup
DROP TABLE objectproperty_vu_prepare_IsTable_table
GO

DROP PROC objectproperty_vu_prepare_IsTable_proc
GO

-- =============== IsView ===============
-- Setup
CREATE VIEW objectproperty_vu_prepare_IsView_view AS
SELECT 1
GO

CREATE TABLE objectproperty_vu_prepare_IsView_table(a int)
GO

-- Test for correct case
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_IsView_view'), 'IsView')
GO

-- Test for incorrect case
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_IsView_table'), 'IsView')
GO

-- Test for invalid object
SELECT OBJECTPROPERTY(0, 'IsView')
GO

-- Cleanup
DROP VIEW objectproperty_vu_prepare_IsView_view
GO

DROP TABLE objectproperty_vu_prepare_IsView_table
GO
-- =============== IsUserTable ===============
-- Setup
CREATE TABLE objectproperty_vu_prepare_IsUserTable_table(a int)
GO

CREATE VIEW objectproperty_vu_prepare_IsUserTable_view AS
SELECT 1
GO

-- Test for correct case
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_IsUserTable_table'), 'IsUserTable')
GO

-- Test for incorrect case
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_IsUserTable_view'), 'IsUserTable')
GO

-- Test for invalid object
SELECT OBJECTPROPERTY(0, 'IsUserTable')
GO

-- Cleanup
DROP TABLE objectproperty_vu_prepare_IsUserTable_table
GO

DROP VIEW objectproperty_vu_prepare_IsUserTable_view
GO

-- =============== IsTableFunction ===============

-- Setup
CREATE FUNCTION objectproperty_vu_prepare_IsTableFunction_tablefunction()
RETURNS @t TABLE (
    c1 int,
    c2 int
)
AS
BEGIN
    INSERT INTO @t
    SELECT 1 as c1, 2 as c2;
    RETURN;
END
GO

CREATE FUNCTION objectproperty_vu_prepare_IsTableFunction_inlinetablefunction()
RETURNS TABLE
AS
RETURN
(
  SELECT 1 AS c1, 2 AS c2
)
GO

CREATE FUNCTION objectproperty_vu_prepare_IsTableFunction_function()
RETURNS INT
AS
BEGIN
RETURN 1
END
GO

-- Test for valid table function (should return 1)
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_IsTableFunction_tablefunction'), 'IsTableFunction')
GO

-- Test for valid inline table function (should return 1)
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_IsTableFunction_inlinetablefunction'), 'IsTableFunction')
GO

-- Test for incorrect case
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_IsTableFunction_function'), 'IsTableFunction')
GO

-- Test for invalid object
SELECT OBJECTPROPERTY(0, 'IsTableFunction')
GO

-- Cleanup
DROP FUNCTION objectproperty_vu_prepare_IsTableFunction_tablefunction
GO

DROP FUNCTION objectproperty_vu_prepare_IsTableFunction_function
GO

DROP FUNCTION objectproperty_vu_prepare_IsTableFunction_inlinetablefunction
GO

-- =============== IsInlineFunction ===============

-- Setup
CREATE FUNCTION objectproperty_vu_prepare_IsInlineFunction_tablefunction()
RETURNS TABLE
AS
RETURN
(
  SELECT 1 AS c1, 2 AS c2
)
GO

CREATE FUNCTION objectproperty_vu_prepare_IsInlineFunction_function()
RETURNS INT
AS
BEGIN
RETURN 1
END
GO

-- Test for correct case (should return 1)
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_IsInlineFunction_tablefunction'), 'IsInlineFunction')
GO

-- Test for incorrect case
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_IsInlineFunction_function'), 'IsInlineFunction')
GO

-- Test for invalid object
SELECT OBJECTPROPERTY(0, 'IsInlineFunction')
GO

-- Cleanup
DROP FUNCTION objectproperty_vu_prepare_IsInlineFunction_tablefunction
GO

DROP FUNCTION objectproperty_vu_prepare_IsInlineFunction_function
GO
-- =============== IsScalarFunction ===============

-- Setup
CREATE FUNCTION objectproperty_vu_prepare_IsScalarFunction_function()
RETURNS INT
AS
BEGIN
    RETURN 1
END
GO

CREATE TABLE objectproperty_vu_prepare_IsScalarFunction_table(a int)
GO

-- Test for correct case
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_IsScalarFunction_function'), 'IsScalarFunction')
GO

-- Test for incorrect case
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_IsScalarFunction_table'), 'IsScalarFunction')
GO

-- Test for invalid object
SELECT OBJECTPROPERTY(0, 'IsScalarFunction')
GO

-- Cleanup
DROP FUNCTION objectproperty_vu_prepare_IsScalarFunction_function
GO

DROP TABLE objectproperty_vu_prepare_IsScalarFunction_table
GO

-- =============== IsPrimaryKey ===============
-- Setup
CREATE TABLE objectproperty_vu_prepare_IsPrimaryKey_table(a int, CONSTRAINT objectproperty_vu_prepare_pk PRIMARY KEY(a))
GO

-- Test for correct case
SELECT OBJECTPROPERTY((SELECT TOP(1) object_id FROM sys.all_objects where name like '%objectproperty_vu_prepare_pk%' ), 'IsPrimaryKey')
GO

-- Test for incorrect case
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_IsPrimaryKey_table'), 'IsPrimaryKey')
GO

-- Test for invalid object
SELECT OBJECTPROPERTY(0, 'IsPrimaryKey')
GO

-- Cleanup
DROP TABLE objectproperty_vu_prepare_IsPrimaryKey_table
GO

-- =============== IsIndexed ===============
-- Setup
CREATE TABLE objectproperty_vu_prepare_IsIndexed_table(a int, CONSTRAINT PK_isprimarykey PRIMARY KEY(a))
GO

CREATE TABLE objectproperty_vu_prepare_IsIndexed_nonindexed_table(a int)
GO

-- Test for correct case
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_IsIndexed_table'), 'IsIndexed')
GO

-- Test for incorrect case
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_IsIndexed_nonindexed_table'), 'IsIndexed')
GO

-- Test for invalid object
SELECT OBJECTPROPERTY(0, 'IsIndexed')
GO

-- Cleanup
DROP TABLE objectproperty_vu_prepare_IsIndexed_nonindexed_table
GO

DROP TABLE objectproperty_vu_prepare_IsIndexed_table
GO

-- =============== IsDefault ===============
-- NOTE: Defaults are currently not supported so will return 0

-- Setup
CREATE TABLE objectproperty_vu_prepare_IsDefault_table(a int)
GO

-- Test for valid object
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_IsDefault_table'), 'IsDefault')
GO

-- Test for invalid object
SELECT OBJECTPROPERTY(0, 'IsDefault')
GO

-- Cleanup
DROP TABLE objectproperty_vu_prepare_IsDefault_table
GO

-- =============== IsRule ===============
-- NOTE: Rules are currently not supported so will return 0

-- Setup
CREATE TABLE objectproperty_vu_prepare_IsRule_table(a int)
GO

-- Test for valid object
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_IsRule_table'), 'IsRule')
GO

-- Test for invalid object
SELECT OBJECTPROPERTY(0, 'IsRule')
GO

-- Cleanup
DROP TABLE objectproperty_vu_prepare_IsRule_table
GO

-- =============== IsTrigger ===============

-- Setup
CREATE TABLE objectproperty_vu_prepare_IsTrigger_table(a int)
GO

CREATE TRIGGER objectproperty_vu_prepare_IsTrigger_trigger ON objectproperty_vu_prepare_IsTrigger_table INSTEAD OF INSERT
AS
BEGIN
    SELECT * FROM objectproperty_vu_prepare_IsTrigger_table
END
GO

-- Test for correct case
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_IsTrigger_trigger', 'TR'), 'IsTrigger')
GO

-- Test for incorrect case
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_IsTrigger_table', 'TR'), 'IsTrigger')
GO

-- Test for invalid object
SELECT OBJECTPROPERTY(0, 'IsTrigger')
GO

-- Cleanup
DROP TABLE objectproperty_vu_prepare_IsTrigger_table
GO

-- Test for dependant objects in upgrade
SELECT * FROM objectproperty_vu_prepare_dep_view
GO

EXEC objectproperty_vu_prepare_dep_proc
GO

SELECT * FROM objectproperty_vu_prepare_dep_func()
GO

