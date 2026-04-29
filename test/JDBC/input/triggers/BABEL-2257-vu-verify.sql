SELECT set_config('babelfishpg_tsql.enable_antlr_parse_cache', 'on', false);
GO

SELECT set_config('babelfishpg_tsql.force_antlr_cache_testing', 'off', false);
GO

exec babel_2257_vu_prepare_error_mapping.ErrorHandling1;
GO

select * from babel_2257_vu_prepare_t1
GO

select * from babel_2257_vu_prepare_t2
GO
