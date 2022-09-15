CREATE DATABASE sys_sp_tables_view_dep_vu_prepare_db1;
GO

USE sys_sp_tables_view_dep_vu_prepare_db1
GO

create table sys_sp_tables_view_dep_vu_prepare_t1 (a int)
GO

create procedure sys_sp_tables_view_dep_vu_prepare_p1 as
    select count(*) from sys.sp_tables_view where TABLE_NAME = 'sys_sp_tables_view_dep_vu_prepare_t1'
GO

create function sys_sp_tables_view_dep_vu_prepare_f1()
returns int
as
begin 
    return (select count(*) from sys.sp_tables_view where TABLE_NAME = 'sys_sp_tables_view_dep_vu_prepare_t1')
end
GO

create view sys_sp_tables_view_dep_vu_prepare_v1 as
    select count(*) from sys.sp_tables_view where TABLE_NAME = 'sys_sp_tables_view_dep_vu_prepare_t1'
GO

