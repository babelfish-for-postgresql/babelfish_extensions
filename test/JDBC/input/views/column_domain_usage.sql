##tests for column_domain_usage##

USE  master;
go

CREATE TYPE typ1 FROM char(32) NOT NULL;
go

CREATE TABLE tb1(a int, b char, c varchar, d typ1);
go

SELECT DOMAIN_CATALOG, DOMAIN_SCHEMA, TABLE_NAME, COLUMN_NAME FROM information_schema.COLUMN_DOMAIN_USAGE WHERE TABLE_NAME NOT LIKE 'sys%' ORDER BY COLUMN_NAME;
go

CREATE DATABASE src;
go

USE src;
go

SELECT DOMAIN_CATALOG, DOMAIN_SCHEMA, TABLE_NAME, TABLE_SCHEMA, COLUMN_NAME FROM information_schema.COLUMN_DOMAIN_USAGE WHERE TABLE_NAME NOT LIKE 'sys%' ORDER BY COLUMN_NAME;
go

CREATE TYPE NTYP FROM varchar(11) NOT NULL;
go

create table col_test( s int, t nvarchar(8), r NTYP);
go

SELECT DOMAIN_NAME, TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME  FROM information_schema.COLUMN_DOMAIN_USAGE WHERE TABLE_NAME NOT LIKE 'sys%' ORDER BY COLUMN_NAME;
go

use master;
go

drop table tb1;
go

drop type typ1;
go

use src;
go

drop table col_test;
go

drop type NTYP;
go

use master;
go

drop database src;
go

create schema sch;
go

create type sch.ty4 from varchar(4) NOT NULL;
go

create table sch.tb4(a char, b int, c sch.ty4);
go

SELECT DOMAIN_NAME, TABLE_CATALOG, TABLE_NAME, DOMAIN_SCHEMA, COLUMN_NAME FROM information_schema.COLUMN_DOMAIN_USAGE WHERE TABLE_NAME NOT LIKE 'sys%' ORDER BY COLUMN_NAME;
go

drop table sch.tb4;
go

drop type sch.ty4;
go

drop schema sch;
go



