-- sla 25000
USE babel_sp_sproc_columns_vu_prepare_db1
GO

-- error: provided name of database we are not currently in
EXEC sp_sproc_columns @procedure_qualifier = 'master'
GO

EXEC sp_sproc_columns @procedure_name = 'babel_sp_sproc_columns_vu_prepare_select_all'
GO

-- pattern matching is default to be ON
EXEC sp_sproc_columns @procedure_name = 'babel_sp_sproc_columns_vu_prepare_select_%'
GO

-- pattern matching set to OFF
EXEC sp_sproc_columns @procedure_name = 'babel_sp_sproc_columns_vu_prepare_select_%', @fUsePattern = '0'
GO

EXEC sp_sproc_columns @procedure_name = 'positive_or_negative', @procedure_owner = 'babel_sp_sproc_columns_vu_prepare_s1', @column_name = '@long'
GO

-- unnamed invocation
EXEC sp_sproc_columns 'babel_sp_sproc_columns_vu_prepare_select_all_with_parameter', 'dbo', 'babel_sp_sproc_columns_vu_prepare_db1'
GO

-- case-insensitive invocation
EXEC SP_SPROC_COLUMNS @PROCEDURE_NAME = 'positive_or_negative', @PROCEDURE_OWNER = 'babel_sp_sproc_columns_vu_prepare_s1', @PROCEDURE_QUALIFIER = 'babel_sp_sproc_columns_vu_prepare_db1'
GO

-- delimiter invocation
exec [sys].[sp_sproc_columns] 'babel_sp_sproc_columns_vu_prepare_select_all_with_parameter'
GO

exec [sp_sproc_columns] 'babel_sp_sproc_columns_vu_prepare_select_all_with_parameter'
GO

-- case-insensitive invocation
EXEC SP_SPROC_COLUMNS 'babel_sp_sproc_columns_vu_prepare_select_all_WITH_PARAMETER', 'DBO', 'babel_sp_sproc_columns_vu_prepare_db1'
GO

-- mixed-parameters procedure
exec sp_sproc_columns 'babel_sp_sproc_columns_vu_prepare_mp_select_all', 'dbo', 'babel_sp_sproc_columns_vu_prepare_db1'
GO

exec sp_sproc_columns 'babel_sp_sproc_columns_vu_prepare_mp_select_all', 'dbo', 'babel_sp_sproc_columns_vu_prepare_db1'
GO

exec sp_sproc_columns 'babel_sp_sproc_columns_vu_prepare_mp_select_all', 'dbo', 'babel_sp_sproc_columns_vu_prepare_db1', '@id'
GO

exec sp_sproc_columns 'babel_sp_sproc_columns_vu_prepare_mp_select_all', 'dbo', 'babel_sp_sproc_columns_vu_prepare_db1', '@ID'
GO

exec sp_sproc_columns 'babel_sp_sproc_columns_vu_prepare_mp_select_all', 'dbo', 'babel_sp_sproc_columns_vu_prepare_db1', '@myvarchar'
GO

exec sp_sproc_columns 'babel_sp_sproc_columns_vu_prepare_mp_select_all', 'dbo', 'babel_sp_sproc_columns_vu_prepare_db1', '@MYVARCHAR'
GO

-- no parameter name procedure
exec sp_sproc_columns 'babel_sp_sproc_columns_vu_prepare_no_param_name'
GO

-- table-value function 
exec sp_sproc_columns 'babel_sp_sproc_columns_vu_prepare_table_value_func'
GO

-- only get procedure existing within current database context
EXEC sp_sproc_columns @procedure_name = 'babel_sp_sproc_columns_vu_prepare_net'
GO

-- Test with user-defined datatypes
EXEC sp_sproc_columns @procedure_name = 'babel_sp_sproc_columns_vu_prepare_eyedees_proc'
GO
EXEC sp_sproc_columns @procedure_name = 'babel_sp_sproc_columns_vu_prepare_eyedees_func'
GO
EXEC sp_sproc_columns @procedure_name = 'babel_sp_sproc_columns_vu_prepare_PhoneNum_func'
GO
EXEC sp_sproc_columns @procedure_name = 'babel_sp_sproc_columns_vu_prepare_Phone_num_proc'
GO

-- Test with a variety of datatypes
EXEC sp_sproc_columns @procedure_name = 'babel_sp_sproc_columns_vu_prepare_addTwo'
GO
EXEC sp_sproc_columns @procedure_name = 'babel_sp_sproc_columns_vu_prepare_complexProc'
GO
EXEC sp_sproc_columns @procedure_name = 'babel_sp_sproc_columns_vu_prepare_tableFunc'
GO
EXEC sp_sproc_columns @procedure_name = 'babel_sp_sproc_columns_vu_prepare_InlineTableFunc'
GO
EXEC sp_sproc_columns @procedure_name = 'babel_sp_sproc_columns_vu_prepare_tableFunc2'
GO
EXEC sp_sproc_columns @procedure_name = 'babel_sp_sproc_columns_vu_prepare_InlineTableFunc2'
GO
EXEC sp_sproc_columns @procedure_name = 'babel_sp_sproc_columns_vu_prepare_tvpProc'
GO
EXEC sp_sproc_columns @procedure_name = 'babel_sp_sproc_columns_vu_prepare_myDecFunc'
GO
EXEC sp_sproc_columns @procedure_name = 'babel_sp_sproc_columns_vu_prepare_typeModifier'
GO
EXEC sp_sproc_columns @procedure_name = 'babel_sp_sproc_columns_vu_prepare_DataTypeExamples'
GO
