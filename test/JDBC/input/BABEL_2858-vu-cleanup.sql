DROP TABLE IF EXISTS babel_2858_t1
GO

DROP TABLE IF EXISTS babel_2858_t1_deleted
GO

SELECT set_config('babelfishpg_tsql.enable_sll_parse_mode', 'false', false)
GO