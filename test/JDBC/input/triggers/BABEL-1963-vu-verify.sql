SELECT set_config('babelfishpg_tsql.enable_antlr_parse_cache', 'on', false);
GO

SELECT set_config('babelfishpg_tsql.force_antlr_cache_testing', 'off', false);
GO

exec babel_1963_vu_prepare_p1
go

insert into babel_1963_vu_prepare_t2 values(5)
go

