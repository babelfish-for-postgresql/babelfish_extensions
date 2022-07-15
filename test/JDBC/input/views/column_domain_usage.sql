##tests for column_domain_usage##
CREATE TYPE column_domain_usage_typ1 FROM char(32) NOT NULL;
go

CREATE TABLE column_domain_usage_tb1(arg1 int, arg2 char, arg3 varchar, arg4 column_domain_usage_typ1);
go

SELECT * FROM information_schema.COLUMN_DOMAIN_USAGE WHERE TABLE_NAME NOT LIKE 'sys%' ORDER BY COLUMN_NAME;
go

CREATE DATABASE db_column_domain_usage;
go

USE db_column_domain_usage;
go

SELECT * FROM information_schema.COLUMN_DOMAIN_USAGE WHERE TABLE_NAME NOT LIKE 'sys%' ORDER BY COLUMN_NAME;
go

CREATE TYPE column_domain_usage_NTYP FROM varchar(11) NOT NULL;
go

create table column_domain_usage_col_test( arg5 int, arg6 nvarchar(8), arg7 column_domain_usage_NTYP);
go

SELECT * FROM information_schema.COLUMN_DOMAIN_USAGE WHERE TABLE_NAME NOT LIKE 'sys%' ORDER BY COLUMN_NAME;
go

drop table column_domain_usage_col_test;
go

drop type column_domain_usage_NTYP;
go

use master;
go

drop table column_domain_usage_tb1;
go

drop type column_domain_usage_typ1;
go

drop database db_column_domain_usage;
go

create schema column_domain_usage_sch;
go

create type column_domain_usage_sch.column_domain_usage_ty4 from varchar(4) NOT NULL;
go

create table column_domain_usage_sch.column_domain_usage_tb4(arg8 char, arg9 int, arg10 column_domain_usage_sch.column_domain_usage_ty4);
go

SELECT * FROM information_schema.COLUMN_DOMAIN_USAGE WHERE TABLE_NAME NOT LIKE 'sys%' ORDER BY COLUMN_NAME;
go

drop table column_domain_usage_sch.column_domain_usage_tb4;
go

drop type column_domain_usage_sch.column_domain_usage_ty4;
go

drop schema column_domain_usage_sch;
go
