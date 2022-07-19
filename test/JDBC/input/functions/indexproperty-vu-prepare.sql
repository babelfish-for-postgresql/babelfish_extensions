use master 
go

-- should auto-name the primary key index as t1_pkey
create table t1(c1 int PRIMARY KEY (c1))
go

-- explicitly create index
-- should auto-name the index as 'idxt2...'
create table t2(c2 int not null)
go
create unique index idx on t2(c2)
go

create procedure sys_indexproperty_vu_prepare_proc 
as 
select INDEXPROPERTY(OBJECT_ID('t1'), 't1_pkey', 'InDexDepTh')
go

create function sys_indexproperty_vu_prepare_func() 
returns int
as 
begin
return (select INDEXPROPERTY(OBJECT_ID('t2'), (select name from sys.indexes where name like 'idxt2%'), 'ISunique'))
end
go