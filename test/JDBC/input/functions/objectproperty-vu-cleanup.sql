USE db1
GO

-- =============== OwnerId ===============

-- Cleanup
DROP TABLE ownerid_schema.ownerid_table
GO

DROP SCHEMA ownerid_schema
GO

-- =============== IsDefaultCnst ===============

-- Cleanup
DROP TABLE isdefaultcnst_table
GO

-- =============== ExecIsQuotedIdentOn ===============

-- Cleanup
DROP PROC execisquotedident_proc_on
GO
DROP PROC execisquotedident_proc_off
GO
DROP TABLE execisquotedident_table
GO

-- =============== IsMSShipped ===============

-- Cleanup
DROP TABLE is_ms_shipped_table
GO

-- =============== TableFullTextPopulateStatus ===============

-- Cleanup
DROP TABLE tablefulltextpopulatestatus_table
GO

DROP PROC tablefulltextpopulatestatus_proc
GO

-- =============== TableHasVarDecimalStorageFormat ===============

-- Cleanup
DROP TABLE TableHasVarDecimalStorageFormat_table
GO

DROP PROC TableHasVarDecimalStorageFormat_proc
GO

-- =============== IsSchemaBound ===============

-- Cleanup
DROP TABLE IsSchemaBound_table
GO

DROP FUNCTION IsSchemaBound_function_false
GO

DROP FUNCTION IsSchemaBound_function_true
GO

-- =============== ExecIsAnsiNullsOn ===============

-- Cleanup
DROP PROC ansi_nulls_off_proc
GO

DROP PROC ansi_nulls_on_proc
GO

DROP TABLE ansi_nulls_on_table
GO

-- =============== IsDeterministic ===============

-- Cleanup

DROP FUNCTION IsDeterministic_function_no
GO

DROP FUNCTION IsDeterministic_function_yes
GO

DROP TABLE IsDeterministic_table
GO

-- =============== IsProcedure ===============

-- Cleanup
DROP PROC IsProcedure_proc
GO

DROP TABLE IsProcedure_table
GO

-- =============== IsTable ===============

-- Cleanup
DROP TABLE IsTable_table
GO

DROP PROC IsTable_proc
GO

-- =============== IsView ===============

-- Cleanup
DROP VIEW IsView_view
GO

DROP TABLE IsView_table
GO

-- =============== IsUserTable ===============
-- Cleanup
DROP TABLE IsUserTable_table
GO

DROP VIEW IsUserTable_view
GO

-- =============== IsTableFunction ===============

-- Cleanup
DROP FUNCTION IsTableFunction_tablefunction
GO

DROP FUNCTION IsTableFunction_function
GO

-- =============== IsInlineFunction ===============

-- Cleanup
DROP FUNCTION IsInlineFunction_tablefunction
GO

DROP FUNCTION IsInlineFunction_function
GO

-- =============== IsScalarFunction ===============

-- Cleanup
DROP FUNCTION IsScalarFunction_function
GO

DROP TABLE IsScalarFunction_table
GO

-- =============== IsPrimaryKey ===============

-- Cleanup
DROP TABLE IsPrimaryKey_table
GO

-- =============== IsIndexed ===============
-- Cleanup
DROP TABLE IsIndexed_nonindexed_table
GO

DROP TABLE IsIndexed_table
GO

-- =============== IsDefault ===============

-- Cleanup
DROP TABLE IsDefault_table
GO

-- =============== IsRule ===============

-- Cleanup
DROP TABLE IsRule_table
GO

-- =============== IsTrigger ===============

-- Cleanup
DROP TABLE IsTrigger_table
GO

-- Global cleanup for tests
USE master
GO
DROP DATABASE db1
GO
