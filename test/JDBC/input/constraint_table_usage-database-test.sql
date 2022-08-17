use master;
go

create table constraint_table_usage_db_test_tb1(arg1 char(10) NOT NULL, arg2 char(10), UNIQUE(arg1,arg2));
go

create database constraint_table_usage_db_test_db;
go

use constraint_table_usage_db_test_db;
go

create table constraint_table_usage_db_test_tb2(arg3 char(10) NOT NULL, arg4 char(10), UNIQUE(arg3,arg4));
go

use master;
go

select * from information_schema.constraint_table_usage where table_name like 'constraint_table_usage_db_test_tb%' order by table_name,constraint_name,table_schema;
go

use constraint_table_usage_db_test_db;
go

select * from information_schema.constraint_table_usage where table_name like 'constraint_table_usage_db_test_tb%' order by table_name,constraint_name,table_schema;
go

drop table constraint_table_usage_db_test_tb2;
go

use master;
go

drop table constraint_table_usage_db_test_tb1;
go

drop database constraint_table_usage_db_test_db;
go

