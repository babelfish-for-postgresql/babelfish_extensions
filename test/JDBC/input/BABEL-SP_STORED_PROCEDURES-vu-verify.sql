USE babel_sp_stored_procedures_vu_prepare_db1
GO
-- error: provided name of database we are not currently in
EXEC sp_stored_procedures @sp_qualifier = 'master'
GO

EXEC sp_stored_procedures @sp_name = 'babel_sp_stored_procedures_vu_prepare_select_all'
GO

EXEC sp_stored_procedures @sp_name = 'positive_or_negative', @sp_owner = 'babel_sp_stored_procedures_vu_prepare_s1'
GO

-- unnamed invocation
EXEC sp_stored_procedures 'babel_sp_stored_procedures_vu_prepare_select_all', 'dbo', 'babel_sp_stored_procedures_vu_prepare_db1'
GO

-- [] delimiter invocation
EXEC [sys].[sp_stored_procedures] 'babel_sp_stored_procedures_vu_prepare_select_all', 'dbo', 'babel_sp_stored_procedures_vu_prepare_db1'
GO

EXEC [sp_stored_procedures] 'babel_sp_stored_procedures_vu_prepare_select_all', 'dbo', 'babel_sp_stored_procedures_vu_prepare_db1'
GO

-- case-insensitive invocation
EXEC SP_STORED_PROCEDURES @SP_NAME = 'positive_or_negative', @SP_OWNER = 'babel_sp_stored_procedures_vu_prepare_s1', @SP_QUALIFIER = 'babel_sp_stored_procedures_vu_prepare_db1'
GO

-- case-insensitive parameters
EXEC sp_stored_procedures 'babel_sp_stored_procedures_vu_prepare_select_all', 'DBO', 'babel_sp_stored_procedures_vu_prepare_DB1'
GO

-- Mixed-case procedure
EXEC sp_stored_procedures 'babel_sp_stored_procedures_vu_prepare_select_all_MIXED'
GO

EXEC sp_stored_procedures 'babel_sp_stored_procedures_vu_prepare_select_all_mixed'
GO

EXEC sp_stored_procedures 'babel_sp_stored_procedures_vu_prepare_select_all_miXed'
GO

-- tests fUsePattern = 0
EXEC sp_stored_procedures @sp_name='babel_sp_stored_procedures_vu_prepare_select_a%', @fusepattern=0
GO

-- tests wildcard patterns
EXEC sp_stored_procedures @sp_name='babel_sp_stored_procedures_vu_prepare_select_a%', @fusepattern=1 
GO

EXEC sp_stored_procedures @sp_name='babel_sp_stored_procedures_vu_prepare_sel_ct_all'
GO

-- NOTE: Incorrect output with [] wildcards, see BABEL-2452
EXEC sp_stored_procedures @sp_name='babel_sp_stored_procedures_vu_prepare_sel[eu]ct_all'
GO

EXEC sp_stored_procedures @sp_name='babel_sp_stored_procedures_vu_prepare_sel[^u]ct_all'
GO

EXEC sp_stored_procedures @sp_name='babel_sp_stored_procedures_vu_prepare_sel[a-u]ct_all'
GO