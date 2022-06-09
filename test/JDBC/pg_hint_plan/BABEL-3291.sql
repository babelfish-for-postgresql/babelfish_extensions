drop table if exists babel_3291_t1
go

create table babel_3291_t1(a1 int PRIMARY KEY, b1 int)
go

set babelfish_showplan_all on
go

select /*+SeqScan(babel_3291_t1)*/ * from babel_3291_t1 where a1 = 1
go

select * from babel_3291_t1 where a1 = 1
go

set babelfish_showplan_all off
go

-- cleanup
drop table babel_3291_t1
go