SELECT set_config('babelfishpg_tsql.enable_antlr_parse_cache', 'on', false);
GO

SELECT set_config('babelfishpg_tsql.force_antlr_cache_testing', 'off', false);
GO

select * from babel_4606
GO

update babel_4606 set b = 100 where a = 1;
GO

select * from babel_4606
GO

select * from babel_4606_2
GO

update babel_4606_2 set b = 100 where a = 1;
go

select * from babel_4606_2
GO

select * from babel_4606_3
GO

update babel_4606_3 set b = 100 where a = 1;
go

select * from babel_4606_3
GO
