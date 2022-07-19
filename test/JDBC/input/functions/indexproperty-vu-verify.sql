use master
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

select INDEXPROPERTY(OBJECT_ID('t2'), (select name from sys.indexes where name like 'idxt2%'), 'ISunique')
go

exec sys_indexproperty_vu_prepare_proc
go

select sys_indexproperty_vu_prepare_func()
go