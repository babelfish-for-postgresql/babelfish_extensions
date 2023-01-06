-- sla 90000
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

-- Test cross db reference to sys schemas
select name from sys_objects_vu_prepare_db1.sys.objects order by name;
GO

use tempdb
GO

select name, type, type_desc from tempdb.sys.objects order by name;
GO

USE master
GO

-- Verify cross db reference, it should show the same rows as displayed by the cross db query above.
select name from sys_objects_vu_prepare_db1.sys.objects order by name;
GO

select name, type, type_desc from tempdb.sys.objects order by name;
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
