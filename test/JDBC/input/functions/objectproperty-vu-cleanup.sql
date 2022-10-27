-- =============== OwnerId ===============
-- Cleanup
DROP TABLE objectproperty_vu_prepare_ownerid_schema.objectproperty_vu_prepare_ownerid_table
GO

DROP SCHEMA objectproperty_vu_prepare_ownerid_schema
GO
-- =============== IsDefaultCnst ===============
-- Cleanup
DROP TABLE objectproperty_vu_prepare_isdefaultcnst_table
GO

DROP TABLE objectproperty_vu_prepare_isdefaultcnst_table2
GO

-- =============== ExecIsQuotedIdentOn ===============
-- Cleanup
DROP PROC objectproperty_vu_prepare_execisquotedident_proc_on
GO
DROP PROC objectproperty_vu_prepare_execisquotedident_proc_off
GO
DROP TABLE objectproperty_vu_prepare_execisquotedident_table
GO

-- =============== IsMSShipped ===============
-- Cleanup
DROP TABLE objectproperty_vu_prepare_is_ms_shipped_table
GO

-- =============== TableFullTextPopulateStatus ===============
-- Cleanup
DROP TABLE objectproperty_vu_prepare_tablefulltextpopulatestatus_table
GO

DROP PROC objectproperty_vu_prepare_tablefulltextpopulatestatus_proc
GO

-- =============== TableHasVarDecimalStorageFormat ===============
-- Cleanup
DROP TABLE objectproperty_vu_prepare_TableHasVarDecimalStorageFormat_table
GO

DROP PROC objectproperty_vu_prepare_TableHasVarDecimalStorageFormat_proc
GO

-- =============== IsSchemaBound ===============
-- Cleanup
DROP TABLE objectproperty_vu_prepare_IsSchemaBound_table
GO

DROP FUNCTION objectproperty_vu_prepare_IsSchemaBound_function_false
GO

DROP FUNCTION objectproperty_vu_prepare_IsSchemaBound_function_true
GO

-- =============== ExecIsAnsiNullsOn ===============
-- Cleanup
DROP PROC objectproperty_vu_prepare_ansi_nulls_off_proc
GO

DROP PROC objectproperty_vu_prepare_ansi_nulls_on_proc
GO

DROP TABLE objectproperty_vu_prepare_ansi_nulls_on_table
GO

-- =============== IsDeterministic ===============
-- Cleanup
DROP FUNCTION objectproperty_vu_prepare_IsDeterministic_function_no
GO

DROP FUNCTION objectproperty_vu_prepare_IsDeterministic_function_yes
GO

DROP TABLE objectproperty_vu_prepare_IsDeterministic_table
GO

-- =============== IsProcedure ===============
-- Cleanup
DROP PROC objectproperty_vu_prepare_IsProcedure_proc
GO

DROP TABLE objectproperty_vu_prepare_IsProcedure_table
GO

-- =============== IsTable ===============
-- Cleanup
DROP TABLE objectproperty_vu_prepare_IsTable_table
GO

DROP PROC objectproperty_vu_prepare_IsTable_proc
GO

-- =============== IsView ===============
-- Cleanup
DROP VIEW objectproperty_vu_prepare_IsView_view
GO

DROP TABLE objectproperty_vu_prepare_IsView_table
GO
-- =============== IsUserTable ===============
-- Cleanup
DROP TABLE objectproperty_vu_prepare_IsUserTable_table
GO

DROP VIEW objectproperty_vu_prepare_IsUserTable_view
GO

-- =============== IsTableFunction ===============
-- Cleanup
DROP FUNCTION objectproperty_vu_prepare_IsTableFunction_tablefunction
GO

DROP FUNCTION objectproperty_vu_prepare_IsTableFunction_function
GO

DROP FUNCTION objectproperty_vu_prepare_IsTableFunction_inlinetablefunction
GO

-- =============== IsInlineFunction ===============
-- Cleanup
DROP FUNCTION objectproperty_vu_prepare_IsInlineFunction_tablefunction
GO

DROP FUNCTION objectproperty_vu_prepare_IsInlineFunction_function
GO
-- =============== IsScalarFunction ===============
-- Cleanup
DROP FUNCTION objectproperty_vu_prepare_IsScalarFunction_function
GO

DROP TABLE objectproperty_vu_prepare_IsScalarFunction_table
GO

-- =============== IsPrimaryKey ===============
-- Cleanup
DROP TABLE objectproperty_vu_prepare_IsPrimaryKey_table
GO

-- =============== IsIndexed ===============
-- Cleanup
DROP TABLE objectproperty_vu_prepare_IsIndexed_nonindexed_table
GO

DROP TABLE objectproperty_vu_prepare_IsIndexed_table
GO

-- =============== IsDefault ===============
-- Cleanup
DROP TABLE objectproperty_vu_prepare_IsDefault_table
GO

-- =============== IsRule ===============
-- Cleanup
DROP TABLE objectproperty_vu_prepare_IsRule_table
GO

-- =============== IsTrigger ===============
-- Cleanup
DROP TABLE objectproperty_vu_prepare_IsTrigger_table
GO
