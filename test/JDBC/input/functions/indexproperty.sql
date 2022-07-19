-- should auto-name the primary key index as t1_pkey
create table t1(c1 int PRIMARY KEY (c1))
go

-- explicitly create index
-- should auto-name the index as 'idxt2...'
create table t2(c2 int not null)
go
create unique index idx on t2(c2)
go

-- A NULL parameter should return NULL
select INDEXPROPERTY(OBJECT_ID('t1'), NULL, 'IsClustered')
go

-- Invalid value for 'property' parameter should return NULL
select INDEXPROPERTY(OBJECT_ID('t1'), 't1_pkey', 'PropertyDoesNotExist')
go

-- case insensitive invocation of 'property' parameter with leading & trailing whitespace - should work as normal
select INDEXPROPERTY(OBJECT_ID('t1'), '     t1_pkey  ', '     InDexDepTh     ')
go

-- test all other valid values of the 'property' parameter, except 'IndexID' as it's not static, on 't1' table index
-- some parameters will have leading/trailing whitespace & case insensitive invocation
select INDEXPROPERTY(OBJECT_ID('t1'), 't1_pkey', 'IndexFillFactor')
go
select INDEXPROPERTY(OBJECT_ID('t1'), 't1_pkey', 'IsAutoStatistics')
go
select INDEXPROPERTY(OBJECT_ID('t1'), 't1_pkey', 'ISCLUSTERED')
go
select INDEXPROPERTY(OBJECT_ID('t1'), '   t1_pkey', 'isdisabled')
go
select INDEXPROPERTY(OBJECT_ID('t1'), 't1_pkey', 'IsFulltextKey')
go
select INDEXPROPERTY(OBJECT_ID('t1'), 't1_pkey', 'IsHypothetical')
go
select INDEXPROPERTY(OBJECT_ID('t1'), 't1_pkey   ', 'IsPadIndex')
go
select INDEXPROPERTY(OBJECT_ID('t1'), 't1_pkey', 'IsPageLockDisallowed')
go
select INDEXPROPERTY(OBJECT_ID('t1'), 't1_pkey', 'IsRowLockDisallowed   ')
go
select INDEXPROPERTY(OBJECT_ID('t1'), 't1_pkey', '   IsStatistics')
go
select INDEXPROPERTY(OBJECT_ID('t1'), 't1_pkey', 'ISunique')
go
select INDEXPROPERTY(OBJECT_ID('t1'), 't1_pkey', 'IsColumnstore')
go
select INDEXPROPERTY(OBJECT_ID('t1'), 't1_pkey', 'IsOptimizedForSequentialKey')
go

-- test all other valid values of the 'property' parameter, except 'IndexID' as it's not static, on 't2' table index
-- some parameters will have leading/trailing whitespace & case insensitive invocation
select INDEXPROPERTY(OBJECT_ID('t2'), (select name from sys.indexes where name like 'idxt2%'), 'IndexFillFactor')
go
select INDEXPROPERTY(OBJECT_ID('t2'), (select name from sys.indexes where name like 'idxt2%'), 'IsAutoStatistics')
go
select INDEXPROPERTY(OBJECT_ID('t2'), (select name from sys.indexes where name like 'idxt2%'), 'ISCLUSTERED')
go
select INDEXPROPERTY(OBJECT_ID('t2'), (select name from sys.indexes where name like 'idxt2%'), 'isdisabled')
go
select INDEXPROPERTY(OBJECT_ID('t2'), (select name from sys.indexes where name like 'idxt2%'), 'IsFulltextKey')
go
select INDEXPROPERTY(OBJECT_ID('t2'), (select name from sys.indexes where name like 'idxt2%'), 'IsHypothetical')
go
select INDEXPROPERTY(OBJECT_ID('t2'), (select name from sys.indexes where name like 'idxt2%'), 'IsPadIndex')
go
select INDEXPROPERTY(OBJECT_ID('t2'), (select name from sys.indexes where name like 'idxt2%'), 'IsPageLockDisallowed')
go
select INDEXPROPERTY(OBJECT_ID('t2'), (select name from sys.indexes where name like 'idxt2%'), 'IsRowLockDisallowed   ')
go
select INDEXPROPERTY(OBJECT_ID('t2'), (select name from sys.indexes where name like 'idxt2%'), '   IsStatistics')
go
select INDEXPROPERTY(OBJECT_ID('t2'), (select name from sys.indexes where name like 'idxt2%'), 'ISunique')
go
select INDEXPROPERTY(OBJECT_ID('t2'), (select name from sys.indexes where name like 'idxt2%'), 'IsColumnstore')
go
select INDEXPROPERTY(OBJECT_ID('t2'), (select name from sys.indexes where name like 'idxt2%'), 'IsOptimizedForSequentialKey')
go

drop table t2
go
drop table t1
go