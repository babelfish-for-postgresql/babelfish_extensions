USE db1_sys_procedures
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

select count(*) from sys.procedures where name = 'proc_test_2';
GO

select count(*) from sys.objects where type = 'P' and name = 'proc_test_2';
GO

select count(*) from sys.all_objects where type = 'P' and name = 'proc_test_2';
GO

select count(*) from sys.sql_modules where object_id = object_id('proc_test_2');
GO

USE db1_sys_procedures
GO

select count(*) from sys.procedures where name = 'proc_test_2';
GO

select count(*) from sys.objects where type = 'P' and name = 'proc_test_2';
GO

select count(*) from sys.all_objects where type = 'P' and name = 'proc_test_2';
GO

select count(*) from sys.sql_modules where object_id = object_id('proc_test_2');
GO