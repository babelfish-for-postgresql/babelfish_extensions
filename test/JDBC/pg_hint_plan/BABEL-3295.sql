drop table if exists babel_3295_t1
go

create table babel_3295_t1(a1 int PRIMARY KEY, b1 int)
go

create index index_babel_3295_t1_b1 on babel_3295_t1(b1)
go

select set_config('babelfishpg_tsql.explain_costs', 'off', false)
go

set babelfish_showplan_all on
go

/*
 * Run a SELECT query and give the hint to follow a index scan
 * The hint should not be applied as the GUC for hint mapping has not ben enabled
 */
select * from babel_3295_t1 (index(index_babel_3295_t1_b1)) where b1 = 1
go

set babelfish_showplan_all off
go

select set_config('babelfishpg_tsql.enable_hint_mapping', 'on', false)
go

set babelfish_showplan_all on
go

/*
 * Run a SELECT query and give the hint to follow a index scan
 * The hint should now be applied as the GUC for hint mapping has ben enabled
 */
select * from babel_3295_t1 (index(index_babel_3295_t1_b1)) where b1 = 1
go

set babelfish_showplan_all off
go

-- cleanup
select set_config('babelfishpg_tsql.enable_hint_mapping', 'off', false);
go

drop table babel_3295_t1
go