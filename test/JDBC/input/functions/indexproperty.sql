-- should auto-name the primary key index as t1_pkey
create table t1(c1 int PRIMARY KEY (c1))
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

-- test all other valid values of the 'property' parameter except 'IndexID' as it's not static
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

drop table t1
go