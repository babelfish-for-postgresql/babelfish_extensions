use column_privileges_vu_prepare_db;
go

select * from information_schema.column_privileges where table_name like 'column_privileges_vu_prepare_tb%' and is_grantable='NO' order by table_name,column_name,privilege_type;
go

revoke REFERENCES on column_privileges_vu_prepare_tb2(arg3) from column_privileges_vu_prepare_user;
go

revoke INSERT on column_privileges_vu_prepare_tb2(arg4) from column_privileges_vu_prepare_user;
go

select * from information_schema.column_privileges where table_name like 'column_privileges_vu_prepare_tb%' and is_grantable='NO' order by table_name,column_name,privilege_type;
go

revoke SELECT on column_privileges_vu_prepare_tb1(arg1) from column_privileges_vu_prepare_user;
go

revoke UPDATE on column_privileges_vu_prepare_tb1(arg2) from column_privileges_vu_prepare_user;
go

select * from information_schema.column_privileges where table_name like 'column_privileges_vu_prepare_tb%' order by table_name,column_name,privilege_type;
go

drop table column_privileges_vu_prepare_tb1;
go

drop table column_privileges_vu_prepare_tb2;
go

drop user column_privileges_vu_prepare_user;
go

drop login column_privileges_vu_prepare_log;
go

use master;
go

drop database column_privileges_vu_prepare_db;
go

