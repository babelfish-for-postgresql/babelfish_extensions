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

select count(*) from sys.sql_modules where object_id = object_id('proc_test_1');
GO

USE master
GO

select count(*) from sys.procedures where name = 'proc_test_1';
GO

select count(*) from sys.objects where type = 'P' and name = 'proc_test_1';
GO

select count(*) from sys.sql_modules where object_id = object_id('proc_test_1');
GO

create proc proc_test_2 as select 2;
GO

select count(*) from sys.procedures where name = 'proc_test_2';
GO

select count(*) from sys.objects where type = 'P' and name = 'proc_test_2';
GO

select count(*) from sys.sql_modules where object_id = object_id('proc_test_2');
GO

USE db1
GO

select count(*) from sys.procedures where name = 'proc_test_2';
GO

select count(*) from sys.objects where type = 'P' and name = 'proc_test_2';
GO

select count(*) from sys.sql_modules where object_id = object_id('proc_test_2');
GO

drop procedure proc_test_1
GO

USE master
GO

drop procedure proc_test_2
GO

DROP DATABASE db1
GO