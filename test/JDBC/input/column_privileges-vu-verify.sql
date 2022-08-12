create login column_privileges_vu_prepare_log WITH PASSWORD = 'YourSecretPassword1234#';
GO

create user column_privileges_vu_prepare_user FOR LOGIN column_privileges_vu_prepare_log;
GO

grant SELECT on column_privileges_vu_prepare_tb1(arg1) to column_privileges_vu_prepare_user;
go

grant UPDATE on column_privileges_vu_prepare_tb1(arg2) to column_privileges_vu_prepare_user;
go

grant INSERT on column_privileges_vu_prepare_tb2(arg3) to column_privileges_vu_prepare_user;
go

grant REFERENCES on column_privileges_vu_prepare_tb2(arg4) to column_privileges_vu_prepare_user;
go

select * from information_schema.column_privileges where table_name like 'column_privileges_vu_prepare_tb%' and is_grantable='NO' order by table_name,column_name,privilege_type;
go

create view column_privileges_vu_verify_view as select * from information_schema.column_privileges where table_name like 'column_privileges_vu_prepare_tb%' and is_grantable='NO' order by table_name,column_name,privilege_type;
go

create procedure column_privileges_vu_verify_proc as select * from information_schema.column_privileges where table_name like 'column_privileges_vu_prepare_tb%' and is_grantable='NO' order by table_name,column_name,privilege_type;
go

create function column_privileges_vu_verify_func() returns table as return(select * from information_schema.column_privileges where table_name like 'column_privileges_vu_prepare_tb%' and is_grantable='NO' order by table_name,column_name,privilege_type);
go

select * from information_schema.column_privileges where table_name like 'column_privileges_vu_prepare_tb%' and is_grantable='NO' order by table_name,column_name,privilege_type;
go

revoke SELECT on column_privileges_vu_prepare_tb1(arg1) from column_privileges_vu_prepare_user;
go

revoke UPDATE on column_privileges_vu_prepare_tb1(arg2) from column_privileges_vu_prepare_user;
go

revoke INSERT on column_privileges_vu_prepare_tb2(arg3) from column_privileges_vu_prepare_user;
go

revoke REFERENCES on column_privileges_vu_prepare_tb2(arg4) from column_privileges_vu_prepare_user;
go

select * from information_schema.column_privileges where table_name like 'column_privileges_vu_prepare_tb%' order by table_name,column_name,privilege_type;
go

drop function column_privileges_vu_verify_func;
go

drop procedure column_privileges_vu_verify_proc;
go

drop view column_privileges_vu_verify_view;
go

drop table column_privileges_vu_prepare_tb1;
go

drop table column_privileges_vu_prepare_tb2;
go

drop user column_privileges_vu_prepare_user;
go

drop login column_privileges_vu_prepare_log;
go

