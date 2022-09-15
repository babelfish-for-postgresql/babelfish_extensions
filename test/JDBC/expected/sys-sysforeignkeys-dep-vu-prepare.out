create table sys_sysforeignkeys_dep_vu_prepare_fk1 (a int, primary key (a))
GO

create table sys_sysforeignkeys_dep_vu_prepare_fk2 (a int, b int, primary key (a), foreign key (b) references sys_sysforeignkeys_dep_vu_prepare_fk1(a))
GO

create procedure sys_sysforeignkeys_dep_vu_prepare_p1 as
    select count(*) from sys.sysforeignkeys where fkeyid = object_id('sys_sysforeignkeys_dep_vu_prepare_fk2')
GO

create function sys_sysforeignkeys_dep_vu_prepare_f1()
returns int 
as
begin
    return (select count(*) from sys.sysforeignkeys where fkeyid = object_id('sys_sysforeignkeys_dep_vu_prepare_fk2'))
end
GO

create view sys_sysforeignkeys_dep_vu_prepare_v1 as
    select count(*) from sys.sysforeignkeys where fkeyid = object_id('sys_sysforeignkeys_dep_vu_prepare_fk2')
GO
