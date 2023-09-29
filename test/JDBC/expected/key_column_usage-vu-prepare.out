CREATE DATABASE key_column_usage_vu_prepare_db;
GO

USE key_column_usage_vu_prepare_db;
GO

CREATE TABLE key_column_usage_vu_prepare_tbl1(arg1 int, arg2 int, primary key(arg1));
GO

CREATE TABLE key_column_usage_vu_prepare_tbl2(arg3 int, arg4 int, primary key(arg3), foreign key(arg4) references key_column_usage_vu_prepare_tbl1(arg1));
GO

CREATE SCHEMA key_column_usage_vu_prepare_sc1;
GO

CREATE TABLE key_column_usage_vu_prepare_tbl3 (arg5 int, arg6 int, primary key (arg5,arg6));
GO

CREATE TABLE key_column_usage_vu_prepare_sc1.key_column_usage_vu_prepare_tbl4 (arg7 int, arg8 int, primary key (arg7) , foreign key (arg7) references key_column_usage_vu_prepare_tbl2(arg3));
GO

CREATE TABLE key_column_usage_vu_prepare_tbl5 (arg9 int, arg10 int, arg11 int, foreign key(arg10,arg11) references key_column_usage_vu_prepare_tbl3(arg5,arg6));
GO

CREATE TABLE key_column_usage_vu_prepare_tbl6(arg12 int primary key, arg13 int not null unique, arg14 int check(arg14>0), arg15 int, foreign key(arg15) references key_column_usage_vu_prepare_sc1.key_column_usage_vu_prepare_tbl4(arg7));
GO

CREATE VIEW key_column_usage_vu_prepare_v1 AS (SELECT * FROM information_schema.key_column_usage WHERE TABLE_NAME LIKE 'key_column_usage_vu_prepare%' ORDER BY constraint_name, column_name);
GO

CREATE PROCEDURE key_column_usage_vu_prepare_p1 AS (SELECT * FROM information_schema.key_column_usage WHERE TABLE_NAME LIKE 'key_column_usage_vu_prepare%' ORDER BY constraint_name, column_name);
GO
