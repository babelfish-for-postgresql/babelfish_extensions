CREATE DATABASE sys_key_constraints_dep_vu_prepare_db1;
GO

USE sys_key_constraints_dep_vu_prepare_db1
GO

create table sys_key_constraints_dep_vu_prepare_uq_1 (a int not null unique)
GO

create procedure sys_key_constraints_dep_vu_prepare_p1 as
    select count(*) from sys.key_constraints where parent_object_id = object_id('sys_key_constraints_dep_vu_prepare_uq_1')
GO

create function sys_key_constraints_dep_vu_prepare_f1()
returns int
as
begin
    return (select count(*) from sys.key_constraints where parent_object_id = object_id('sys_key_constraints_dep_vu_prepare_uq_1'))
end
GO

use master
GO

create view sys_key_constraints_dep_vu_prepare_v1 as
    select count(*) from sys.key_constraints where parent_object_id = object_id('sys_key_constraints_dep_vu_prepare_uq_1')
GO
