CREATE TYPE column_domain_usage_vu_prepare_typ1 FROM char(32) NOT NULL;
go

CREATE TABLE column_domain_usage_vu_prepare_tb1(arg1 int, arg2 char, arg3 varchar, arg4 column_domain_usage_vu_prepare_typ1);
go

CREATE DATABASE column_domain_usage_vu_prepare_db;
go

USE column_domain_usage_vu_prepare_db;
go

CREATE TYPE column_domain_usage_vu_prepare_NTYP FROM varchar(11) NOT NULL;
go

create table column_domain_usage_vu_prepare_col_test(arg5 int, arg6 nvarchar(8), arg7 column_domain_usage_vu_prepare_NTYP);
go
