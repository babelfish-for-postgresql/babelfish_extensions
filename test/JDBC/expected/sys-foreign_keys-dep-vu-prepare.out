CREATE DATABASE sys_foreign_keys_dep_vu_prepare_db1;
GO

USE sys_foreign_keys_dep_vu_prepare_db1;
GO

create table sys_foreign_keys_dep_vu_prepare_fk_1 (a int, primary key (a));
GO

create table sys_foreign_keys_dep_vu_prepare_fk_2 (a int, b int, primary key (a), foreign key (b) references sys_foreign_keys_dep_vu_prepare_fk_1(a));
GO

create procedure sys_foreign_keys_dep_vu_prepare_p1 as
    select count(*) from sys.foreign_keys where parent_object_id = object_id('sys_foreign_keys_dep_vu_prepare_fk_2');
GO

create function sys_foreign_keys_dep_vu_prepare_f1()
returns int
as
begin
    return (select count(*) from sys.foreign_keys where parent_object_id = object_id('sys_foreign_keys_dep_vu_prepare_fk_1'))
end
GO

create view sys_foreign_keys_dep_vu_prepare_v1 as 
    select count(*) from sys.foreign_keys where parent_object_id = object_id('sys_foreign_keys_dep_vu_prepare_fk_2')
GO
