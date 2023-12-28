-- parallel_query_expected
drop table if exists babel_3295_t1
go

drop table if exists babel_3295_t2
go

create table babel_3295_t1(a1 int PRIMARY KEY, b1 int)
go

create index index_babel_3295_t1_b1 on babel_3295_t1(b1)
go

create table babel_3295_t2(a2 int PRIMARY KEY, b2 int)
go

select set_config('babelfishpg_tsql.explain_costs', 'off', false)
go

set babelfish_showplan_all on
go

/*
 * Run multiple queries and give different hints
 * The hints should not be applied as the GUC babelfishpg_tsql.enable_pg_hint has not been enabled
 */
select * from babel_3295_t1 (index(index_babel_3295_t1_b1)) where b1 = 1
go

select * from babel_3295_t1 where b1 = 1 option(table hint(babel_3295_t1, index(index_babel_3295_t1_b1)))
go

select * from babel_3295_t1 inner merge join babel_3295_t2 on babel_3295_t1.a1 = babel_3295_t2.a2
go

select * from babel_3295_t1 join babel_3295_t2 on babel_3295_t1.a1 = babel_3295_t2.a2 option(merge join)
go

set babelfish_showplan_all off
go

select set_config('babelfishpg_tsql.enable_pg_hint', 'on', false);
go

set babelfish_showplan_all on
go

/*
 * Run the queries again
 * The hints should now be applied as the GUC for hint mapping has ben enabled
 */
select * from babel_3295_t1 (index(index_babel_3295_t1_b1)) where b1 = 1
go

select * from babel_3295_t1 where b1 = 1 option(table hint(babel_3295_t1, index(index_babel_3295_t1_b1)))
go

select * from babel_3295_t1 inner merge join babel_3295_t2 on babel_3295_t1.a1 = babel_3295_t2.a2
go

select * from babel_3295_t1 join babel_3295_t2 on babel_3295_t1.a1 = babel_3295_t2.a2 option(merge join)
go

set babelfish_showplan_all off
go

-- cleanup
drop table babel_3295_t1
go

drop table babel_3295_t2
go
