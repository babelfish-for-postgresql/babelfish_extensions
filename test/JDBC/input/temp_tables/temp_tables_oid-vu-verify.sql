-- Tables typically consume three OIDs - we checked this in permanent tables.
create table #temp_tables_oid_t1(a int)
create table #temp_tables_oid_t2(a int)
select object_id('#temp_tables_oid_t2') - object_id('#temp_tables_oid_t1')
go

drop table #temp_tables_oid_t1
drop table #temp_tables_oid_t2
go

create table temp_tables_oid_perm_tab_3(a int)
go

-- Should be empty here
select relname from sys.babelfish_get_enr_list()
GO

-- 1 entry expected, just the table. 
CREATE TABLE #temp_tables_oid_t1(a int, b int)
GO

select count(*) from sys.babelfish_get_enr_list()
GO

-- 2 entries expected, the table and the index.
CREATE INDEX temp_tables_oid_idx1 on #temp_tables_oid_t1(a)
GO

select count(*) from sys.babelfish_get_enr_list()
GO

-- 3 entries expected, the table and 2 index
CREATE INDEX #temp_tables_oid_idx2 on #temp_tables_oid_t1(b)
GO

select count(*) from sys.babelfish_get_enr_list()
GO

drop table #temp_tables_oid_t1
GO

-- 0 entries expected
select count(*) from sys.babelfish_get_enr_list()
GO

-- identity and primary key should be in ENR as well

create table #temp_tables_oid_t1(a int identity primary key, b int)
go

select relname from sys.babelfish_get_enr_list()
go

-- general constraint checks

create table #temp_tables_oid_t2(a int unique not null, b int)
go

create table #temp_tables_oid_t3(a int, b int CHECK (b > a))
go

-- Ensure no dependency ordering issues when dropping tables

drop table #temp_tables_oid_t3
go

drop table #temp_tables_oid_t2
go

drop table #temp_tables_oid_t1
go

-- At the end of all the temp table creation, let's ensure that the permanent OID count did not increase
-- This should be 3 when temp OID generation is turned on. 
create table temp_tables_oid_perm_tab_4(a int)
if  (object_id('temp_tables_oid_perm_tab_4') - object_id('temp_tables_oid_perm_tab_3')) = 3
    select true;
else
    select false;
go
