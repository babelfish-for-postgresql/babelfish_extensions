-- Drop the table if it exists already and create a new table
drop table if exists babel_3291_t1
go

create table babel_3291_t1(a1 int PRIMARY KEY, b1 int)
go

-- Switch the session variable to show the query plan to ON
set babelfish_showplan_all on
go

-- Run a SELECT query without any hints. The query plan will use an index scan in this case
select * from babel_3291_t1 where a1 = 1
go

-- Run a SELECT query and give the hint to follow a sequential scan. The query plan should now use a sequential scan
select /*+SeqScan(babel_3291_t1)*/ * from babel_3291_t1 where a1 = 1
go

-- Switch the session variable to show the query plan to OFF
set babelfish_showplan_all off
go

-- cleanup
drop table babel_3291_t1
go