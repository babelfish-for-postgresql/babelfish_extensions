USE sys_objects_vu_prepare_db1
GO

select count(*) from sys.objects where type = 'P' and name = 'sys_objects_vu_prepare_proc1';
GO

select count(*) from sys.all_objects where type = 'P' and name = 'sys_objects_vu_prepare_proc1';
GO

select count(*) from sys.sql_modules where object_id = object_id('sys_objects_vu_prepare_proc1');
GO

select parent_object_id from sys.objects where type = 'P' and name = 'sys_objects_vu_prepare_proc1';
GO

USE master
GO

select count(*) from sys.objects where type = 'P' and name = 'sys_objects_vu_prepare_proc1';
GO

select count(*) from sys.all_objects where type = 'P' and name = 'sys_objects_vu_prepare_proc1';
GO

select count(*) from sys.sql_modules where object_id = object_id('sys_objects_vu_prepare_proc1');
GO

select parent_object_id from sys.objects where type = 'P' and name = 'sys_objects_vu_prepare_proc1';
GO

select count(*) from sys.objects where type = 'P' and name = 'sys_objects_vu_prepare_proc2';
GO

select count(*) from sys.all_objects where type = 'P' and name = 'sys_objects_vu_prepare_proc2';
GO

select count(*) from sys.sql_modules where object_id = object_id('sys_objects_vu_prepare_proc2');
GO

USE sys_objects_vu_prepare_db1
GO

select count(*) from sys.objects where type = 'P' and name = 'sys_objects_vu_prepare_proc2';
GO

select count(*) from sys.all_objects where type = 'P' and name = 'sys_objects_vu_prepare_proc2';
GO

select count(*) from sys.sql_modules where object_id = object_id('sys_objects_vu_prepare_proc2');
GO

USE master
GO

SELECT * FROM sys_objects_vu_prepare_view
GO

EXEC sys_objects_vu_prepare_proc
GO

SELECT dbo.sys_objects_vu_prepare_func()
GO