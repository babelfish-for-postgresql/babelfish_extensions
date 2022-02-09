CREATE DATABASE db1;
GO

USE db1
GO

create table tbl_1 (a int)
GO

select count(*) from sys.sp_tables_view where TABLE_NAME = 'tbl_1';
GO

exec sys.sp_tables @table_name = 'tbl_1';
GO

USE master
GO

select count(*) from sys.sp_tables_view where TABLE_NAME = 'tbl_1';
GO

exec sys.sp_tables @table_name = 'tbl_1';
GO

create table tbl_2 (a int)
GO

select count(*) from sys.sp_tables_view where TABLE_NAME = 'tbl_2';
GO

exec sys.sp_tables @table_name = 'tbl_2';
GO

USE db1
GO

select count(*) from sys.sp_tables_view where TABLE_NAME = 'tbl_2';
GO

exec sys.sp_tables @table_name = 'tbl_2';
GO

drop table tbl_1;
GO

USE master
GO

drop table tbl_2;
GO

DROP DATABASE db1
GO