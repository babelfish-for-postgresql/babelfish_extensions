create database sys_sp_databases_dep_vu_prepare_db1;
go
use sys_sp_databases_dep_vu_prepare_db1;
go
create table sys_sp_databases_dep_vu_prepare_t1(a int);
go
insert into sys_sp_databases_dep_vu_prepare_t1(a) values(10);
go

create procedure sys_sp_databases_dep_vu_prepare_p1 as
    select database_name, remarks from sys.sp_databases_view where database_name='sys_sp_databases_dep_vu_prepare_db1'
go

create function sys_sp_databases_dep_vu_prepare_f1()
returns int
as
begin
    return (select COUNT(*) from sys.sp_databases_view where database_name='sys_sp_databases_dep_vu_prepare_db1')
end
go

create view sys_sp_databases_dep_vu_prepare_v1 as
    select database_name, remarks from sys.sp_databases_view where database_name='sys_sp_databases_dep_vu_prepare_db1'
go
