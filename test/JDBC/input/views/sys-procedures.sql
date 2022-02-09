CREATE DATABASE db1;
GO

USE db1
GO

create proc proc_test_1 as select 1;
GO

select count(*) from sys.procedures where name = 'proc_test_1';
GO

select count(*) from sys.objects where type = 'P' and name = 'proc_test_1';
GO

select count(*) from sys.all_objects where type = 'P' and name = 'proc_test_1';
GO

select count(*) from sys.sql_modules where object_id = object_id('proc_test_1');
GO

select parent_object_id from sys.objects where type = 'P' and name = 'proc_test_1';
GO

create table t24(a int, b varchar(10))
GO

create trigger tr24 on t24 for insert as print 'this is tr24'
GO

select count(*) from sys.procedures where name = 'tr24' and type = 'TR' and parent_object_id = object_id('t24') and parent_object_id != 0;
GO

USE master
GO

select count(*) from sys.procedures where name = 'proc_test_1';
GO

select count(*) from sys.objects where type = 'P' and name = 'proc_test_1';
GO

select count(*) from sys.all_objects where type = 'P' and name = 'proc_test_1';
GO

select count(*) from sys.sql_modules where object_id = object_id('proc_test_1');
GO

select parent_object_id from sys.objects where type = 'P' and name = 'proc_test_1';
GO

select count(*) from sys.procedures where name = 'tr24' and type = 'TR' and parent_object_id = object_id('t24') and parent_object_id != 0;
GO

create proc proc_test_2 as select 2;
GO

select count(*) from sys.procedures where name = 'proc_test_2';
GO

select count(*) from sys.objects where type = 'P' and name = 'proc_test_2';
GO

select count(*) from sys.all_objects where type = 'P' and name = 'proc_test_2';
GO

select count(*) from sys.sql_modules where object_id = object_id('proc_test_2');
GO

USE db1
GO

select count(*) from sys.procedures where name = 'proc_test_2';
GO

select count(*) from sys.objects where type = 'P' and name = 'proc_test_2';
GO

select count(*) from sys.all_objects where type = 'P' and name = 'proc_test_2';
GO

select count(*) from sys.sql_modules where object_id = object_id('proc_test_2');
GO

drop procedure proc_test_1
GO

drop trigger tr24 
GO

drop table t24
GO

USE master
GO

drop procedure proc_test_2
GO

DROP DATABASE db1
GO
