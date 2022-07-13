CREATE TYPE typ1 FROM char(32) NOT NULL;
go

CREATE TABLE tb1(a int, b char, c varchar, d typ1);
go

CREATE DATABASE db_column_domain_usage;
go

USE db_column_domain_usage;
go

CREATE TYPE NTYP FROM varchar(11) NOT NULL;
go

create table col_test( s int, t nvarchar(8), r NTYP);
go
