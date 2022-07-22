use master
go

-- A NULL parameter should return NULL
select INDEXPROPERTY(OBJECT_ID('indexproperty_vu_prepare_table1'), NULL, 'IsClustered')
go

-- Invalid value for 'property' parameter should return NULL
select INDEXPROPERTY(OBJECT_ID('indexproperty_vu_prepare_table1'), 'indexproperty_vu_prepare_table1_pkey', 'PropertyDoesNotExist')
go

-- case insensitive invocation of 'property' parameter with leading & trailing whitespace - should work as normal
select INDEXPROPERTY(OBJECT_ID('indexproperty_vu_prepare_table1'), '     indexproperty_vu_prepare_table1_pkey  ', '     InDexDepTh     ')
go

-- test all other valid values of the 'property' parameter, except 'IndexID' as it's not static, on 'indexproperty_vu_prepare_table1' table index
-- some parameters will have leading/trailing whitespace & case insensitive invocation
select INDEXPROPERTY(OBJECT_ID('indexproperty_vu_prepare_table1'), 'indexproperty_vu_prepare_table1_pkey', 'IndexFillFactor')
go
select INDEXPROPERTY(OBJECT_ID('indexproperty_vu_prepare_table1'), 'indexproperty_vu_prepare_table1_pkey', 'IsAutoStatistics')
go
select INDEXPROPERTY(OBJECT_ID('indexproperty_vu_prepare_table1'), 'indexproperty_vu_prepare_table1_pkey', 'ISCLUSTERED')
go
select INDEXPROPERTY(OBJECT_ID('indexproperty_vu_prepare_table1'), '   indexproperty_vu_prepare_table1_pkey', 'isdisabled')
go
select INDEXPROPERTY(OBJECT_ID('indexproperty_vu_prepare_table1'), 'indexproperty_vu_prepare_table1_pkey', 'IsFulltextKey')
go
select INDEXPROPERTY(OBJECT_ID('indexproperty_vu_prepare_table1'), 'indexproperty_vu_prepare_table1_pkey', 'IsHypothetical')
go
select INDEXPROPERTY(OBJECT_ID('indexproperty_vu_prepare_table1'), 'indexproperty_vu_prepare_table1_pkey   ', 'IsPadIndex')
go
select INDEXPROPERTY(OBJECT_ID('indexproperty_vu_prepare_table1'), 'indexproperty_vu_prepare_table1_pkey', 'IsPageLockDisallowed')
go
select INDEXPROPERTY(OBJECT_ID('indexproperty_vu_prepare_table1'), 'indexproperty_vu_prepare_table1_pkey', 'IsRowLockDisallowed   ')
go
select INDEXPROPERTY(OBJECT_ID('indexproperty_vu_prepare_table1'), 'indexproperty_vu_prepare_table1_pkey', '   IsStatistics')
go
select INDEXPROPERTY(OBJECT_ID('indexproperty_vu_prepare_table1'), 'indexproperty_vu_prepare_table1_pkey', 'ISunique')
go
select INDEXPROPERTY(OBJECT_ID('indexproperty_vu_prepare_table1'), 'indexproperty_vu_prepare_table1_pkey', 'IsColumnstore')
go
select INDEXPROPERTY(OBJECT_ID('indexproperty_vu_prepare_table1'), 'indexproperty_vu_prepare_table1_pkey', 'IsOptimizedForSequentialKey')
go

-- test all other valid values of the 'property' parameter, except 'IndexID' as it's not static, on 'indexproperty_vu_prepare_table2' table index
-- some parameters will have leading/trailing whitespace & case insensitive invocation
select INDEXPROPERTY(OBJECT_ID('indexproperty_vu_prepare_table2'), (select name from sys.indexes where name like 'indexproperty_vu_prepare_idx%'), 'IndexFillFactor')
go
select INDEXPROPERTY(OBJECT_ID('indexproperty_vu_prepare_table2'), (select name from sys.indexes where name like 'indexproperty_vu_prepare_idx%'), 'IsAutoStatistics')
go
select INDEXPROPERTY(OBJECT_ID('indexproperty_vu_prepare_table2'), (select name from sys.indexes where name like 'indexproperty_vu_prepare_idx%'), 'ISCLUSTERED')
go
select INDEXPROPERTY(OBJECT_ID('indexproperty_vu_prepare_table2'), (select name from sys.indexes where name like 'indexproperty_vu_prepare_idx%'), 'isdisabled')
go
select INDEXPROPERTY(OBJECT_ID('indexproperty_vu_prepare_table2'), (select name from sys.indexes where name like 'indexproperty_vu_prepare_idx%'), 'IsFulltextKey')
go
select INDEXPROPERTY(OBJECT_ID('indexproperty_vu_prepare_table2'), (select name from sys.indexes where name like 'indexproperty_vu_prepare_idx%'), 'IsHypothetical')
go
select INDEXPROPERTY(OBJECT_ID('indexproperty_vu_prepare_table2'), (select name from sys.indexes where name like 'indexproperty_vu_prepare_idx%'), 'IsPadIndex')
go
select INDEXPROPERTY(OBJECT_ID('indexproperty_vu_prepare_table2'), (select name from sys.indexes where name like 'indexproperty_vu_prepare_idx%'), 'IsPageLockDisallowed')
go
select INDEXPROPERTY(OBJECT_ID('indexproperty_vu_prepare_table2'), (select name from sys.indexes where name like 'indexproperty_vu_prepare_idx%'), 'IsRowLockDisallowed   ')
go
select INDEXPROPERTY(OBJECT_ID('indexproperty_vu_prepare_table2'), (select name from sys.indexes where name like 'indexproperty_vu_prepare_idx%'), '   IsStatistics')
go
select INDEXPROPERTY(OBJECT_ID('indexproperty_vu_prepare_table2'), (select name from sys.indexes where name like 'indexproperty_vu_prepare_idx%'), 'ISunique')
go
select INDEXPROPERTY(OBJECT_ID('indexproperty_vu_prepare_table2'), (select name from sys.indexes where name like 'indexproperty_vu_prepare_idx%'), 'IsColumnstore')
go
select INDEXPROPERTY(OBJECT_ID('indexproperty_vu_prepare_table2'), (select name from sys.indexes where name like 'indexproperty_vu_prepare_idx%'), 'IsOptimizedForSequentialKey')
go

exec sys_indexproperty_vu_prepare_proc
go

select sys_indexproperty_vu_prepare_func()
go