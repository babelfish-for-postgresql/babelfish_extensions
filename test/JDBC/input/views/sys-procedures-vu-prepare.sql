CREATE DATABASE db1_sys_procedures;
GO

USE db1_sys_procedures
GO

create proc proc_test_1 as select 1;
GO

create table t24(a int, b varchar(10))
GO

create trigger tr24 on t24 for insert as print 'this is tr24'
GO

USE master
GO

create proc proc_test_2 as select 2;
GO