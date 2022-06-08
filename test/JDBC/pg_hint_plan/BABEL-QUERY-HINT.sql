drop table if exists jira3291
go

create table jira3291(a1 int PRIMARY KEY, b1 int)
go

set babelfish_showplan_all on
go

select /*+SeqScan(jira3291)*/ * from jira3291 where a1 = 1
go

select * from jira3291 where a1 = 1
go

set babelfish_showplan_all off
go

-- cleanup
drop table jira3291
go