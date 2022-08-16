use master;
go

create login column_privileges_db_test_log WITH PASSWORD = 'YourSecretPassword1234#';
go

create user column_privileges_db_test_u1 for login column_privileges_db_test_log;
go

create table column_privileges_db_test_tb1(arg1 int, arg2 int);
go

grant SELECT on column_privileges_db_test_tb1(arg1) to column_privileges_db_test_u1;
go

create database column_privileges_db_test_db;
go

use column_privileges_db_test_db;
go

create user column_privileges_db_test_u2 for login column_privileges_db_test_log;
go

create table column_privileges_db_test_tb2(arg3 int, arg4 int);
go

grant SELECT on column_privileges_db_test_tb2(arg3) to column_privileges_db_test_u2;
go

use master;
go

select * from information_schema.column_privileges where table_name like 'column_privileges_db_test_tb%' and is_grantable='NO' order by table_name,column_name,privilege_type;
go

use column_privileges_db_test_db;
go

select * from information_schema.column_privileges where table_name like 'column_privileges_db_test_tb%' and is_grantable='NO' order by table_name,column_name,privilege_type;
go

drop table column_privileges_db_test_tb2;
go

drop user column_privileges_db_test_u2;
go

use master;
go

drop table column_privileges_db_test_tb1;
go

drop user column_privileges_db_test_u1;
go

drop database column_privileges_db_test_db;
go

drop login column_privileges_db_test_log;
go


