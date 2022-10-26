SELECT current_setting( 'babelfishpg_tsql.enable_metadata_inconsistency_check')
GO

SELECT SET_CONFIG('babelfishpg_tsql.enable_metadata_inconsistency_check','off',true)
GO

SELECT current_setting( 'babelfishpg_tsql.enable_metadata_inconsistency_check')
GO

SELECT SET_CONFIG('babelfishpg_tsql.enable_metadata_inconsistency_check','on',true)
GO
