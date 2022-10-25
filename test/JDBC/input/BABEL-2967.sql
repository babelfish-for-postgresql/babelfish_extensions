select current_setting( 'babelfishpg_tsql.enable_metadata_inconsistency_check')
GO


SELECT SET_CONFIG('babelfishpg_tsql.enable_metadata_inconsistency_check','off',true)
GO

 select current_setting( 'babelfishpg_tsql.enable_metadata_inconsistency_check')
GO

SELECT SET_CONFIG('babelfishpg_tsql.enable_metadata_inconsistency_check','false',true)
GO
