drop table if exists babel_3292_t1
go

create table babel_3292_t1(a1 int PRIMARY KEY, b1 int)
go

create index index_babel_3292_t1_b1 on babel_3292_t1(b1)
go

set babelfish_showplan_all on
go

/*
 * Run a SELECT query without any hints to ensure that un-hinted queries still work.
 * This also ensures that when the SELECT query is not hinted it produces a different plan(bitmap heap scan and bitmap index scan)
 * than the index scan that we're hinting in the query below. This verifies that the next test is actually valid.
 * If the planner was going to choose a sequential scan anyway, the next test wouldn't actually prove that hints were working.
 */
select * from babel_3292_t1 where b1 = 1
go

/*
 * Run SELECT queries and give the hint to follow a index scan. 
 * The query plan should now use a idex scan instead of the bitmap heap and bitmap index scan it uses in the un-hinted test above.
 */
select * from babel_3292_t1 (index(index_babel_3292_t1_b1)) where b1 = 1
go

select * from babel_3292_t1 (index=index_babel_3292_t1_b1) where b1 = 1
go

set babelfish_showplan_all off
go

-- cleanup
drop table babel_3292_t1
go
