-- tsql

use master;
go

create login key_column_usage_privilege_test_user with password='';
go

create database key_column_usage_privilege_test_db;
go

use key_column_usage_privilege_test_db;
go

create table key_column_usage_privilege_test_tb(arg1 int, arg2 int, primary key(arg1));
go

create user key_column_usage_privilege_test_user for login key_column_usage_privilege_test_user;
go

use master;
go

-- tsql user=key_column_usage_privilege_test_user password=''

use key_column_usage_privilege_test_db;
go

select * from information_schema.key_column_usage where table_name='key_column_usage_privilege_test_tb';
go

use master;
go

-- tsql

use key_column_usage_privilege_test_db;
go

grant select on key_column_usage_privilege_test_tb to key_column_usage_privilege_test_user;
go

use master;
go

-- tsql user=key_column_usage_privilege_test_user password=''

use key_column_usage_privilege_test_db;
go

select * from information_schema.key_column_usage where table_name='key_column_usage_privilege_test_tb';
go

use master;
go

-- tsql

use key_column_usage_privilege_test_db;
go

drop table key_column_usage_privilege_test_tb;
go

use master;
go

drop database key_column_usage_privilege_test_db;
go

-- tsql
drop login key_column_usage_privilege_test_user;
go