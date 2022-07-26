use master 
go

-- should auto-name the primary key index as 'indexproperty_vu_prepare_table1_pkey'
create table indexproperty_vu_prepare_table1(c1 int PRIMARY KEY (c1))
go

-- explicitly create index
-- should auto-name the index as 'indexproperty_vu_prepare_idx...'
create table indexproperty_vu_prepare_table2(c2 int not null)
go
create unique index indexproperty_vu_prepare_idx on indexproperty_vu_prepare_table2(c2)
go

create procedure sys_indexproperty_vu_prepare_proc 
as 
select INDEXPROPERTY(OBJECT_ID('indexproperty_vu_prepare_table1'), 'indexproperty_vu_prepare_table1_pkey', 'InDexDepTh')
go

create function sys_indexproperty_vu_prepare_func() 
returns int
as 
begin
return (select INDEXPROPERTY(OBJECT_ID('indexproperty_vu_prepare_table2'), (select name from sys.indexes where name like 'indexproperty_vu_prepare_idx%'), 'ISunique'))
end
go