BEGIN TRANSACTION babel_4815
GO

SELECT set_config('debug_parallel_query', '1', true)
SELECT set_config('parallel_setup_cost', '0', true)
SELECT set_config('parallel_tuple_cost', '0', true)
select set_config('max_parallel_workers_per_gather', '1', true);
SELECT set_config('babelfishpg_tsql.explain_costs', 'off', false)
GO

SET BABELFISH_SHOWPLAN_ALL on
GO

select * from babel_4815_1;
go

select * from babel_4815_2;
go

select * from babel_4815_3;
go

select * from babel_4815_4;
go

select * from babel_4815_5;
go

select * from babel_4815_6;
go

select * from babel_4815_7;
go

select * from babel_4815_8;
go

select * from babel_4815_9;
go

select * from babel_4815_10;
go

select * from babel_4815_11;
go

select * from babel_4815_12;
go

select * from babel_4815_13;
go

select * from babel_4815_14;
go

select * from babel_4815_15;
go

select * from babel_4815_16;
go

select * from babel_4815_17;
go

select * from babel_4815_18;
go


SET BABELFISH_SHOWPLAN_ALL off
go

SELECT set_config('babelfishpg_tsql.explain_costs', 'on', false)
GO

commit TRANSACTION babel_4815;
GO
