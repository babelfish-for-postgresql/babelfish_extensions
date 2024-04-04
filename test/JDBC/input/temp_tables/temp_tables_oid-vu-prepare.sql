-- Sanity check first - ensure that normal tables follow this assumption as well (in case something changes in PG implementation)
create table temp_tables_oid_perm_tab_1(a int)
go
create table temp_tables_oid_perm_tab_2(a int)
go

select object_id('temp_tables_oid_perm_tab_2') - object_id('temp_tables_oid_perm_tab_1')
go
