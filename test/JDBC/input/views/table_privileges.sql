create table table_privileges_vu_prepare_tb1(arg1 int, arg2 int);
go

create table table_privileges_vu_prepare_tb2(arg3 int, arg4 int);
go

create login table_privileges_vu_prepare_log WITH PASSWORD = 'YourSecretPassword1234#';
GO

create user table_privileges_vu_prepare_user FOR LOGIN table_privileges_vu_prepare_log;
GO

grant SELECT on table_privileges_vu_prepare_tb1 to table_privileges_vu_prepare_user;
go

grant UPDATE on table_privileges_vu_prepare_tb1 to table_privileges_vu_prepare_user;
go

grant REFERENCES on table_privileges_vu_prepare_tb2 to table_privileges_vu_prepare_user;
go

select * from information_schema.table_privileges where table_name like 'table_privileges_vu_prepare_tb%' and is_grantable = 'NO' order by table_name,privilege_type;
go


create view table_privileges_vu_verify_view as select * from information_schema.table_privileges where table_name like 'table_privileges_vu_prepare_tb%' and is_grantable='NO' order by table_name,table_name,privilege_type;
go

create procedure table_privileges_vu_verify_proc as select * from information_schema.table_privileges where table_name like 'table_privileges_vu_prepare_tb%' and is_grantable='NO' order by table_name,table_name,privilege_type;
go

create function table_privileges_vu_verify_func() returns table as return(select * from information_schema.table_privileges where table_name like 'table_privileges_vu_prepare_tb%' and is_grantable='NO' order by table_name,table_name,privilege_type);
go

select * from information_schema.table_privileges where table_name like 'table_privileges_vu_prepare_tb%' and is_grantable = 'NO' order by table_name,privilege_type;
go

revoke SELECT on table_privileges_vu_prepare_tb1 from table_privileges_vu_prepare_user;
go

revoke UPDATE on table_privileges_vu_prepare_tb1 from table_privileges_vu_prepare_user;
go

revoke REFERENCES on table_privileges_vu_prepare_tb2 from table_privileges_vu_prepare_user;
go

select * from information_schema.table_privileges where table_name like 'table_privileges_vu_prepare_tb%' order by table_name,privilege_type;
go

drop function table_privileges_vu_verify_func;
go

drop procedure table_privileges_vu_verify_proc;
go

drop view table_privileges_vu_verify_view;
go

drop table table_privileges_vu_prepare_tb1;
go

drop table table_privileges_vu_prepare_tb2;
go

drop user table_privileges_vu_prepare_user;
go

drop login table_privileges_vu_prepare_log;
go