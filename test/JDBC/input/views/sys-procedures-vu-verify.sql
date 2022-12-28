-- sla 70000
USE sys_procedures_vu_prepare_db1
GO

select count(*) from sys.procedures where name = 'sys_procedures_vu_prepare_proc1';
GO

select count(*) from sys.objects where type = 'P' and name = 'sys_procedures_vu_prepare_proc1';
GO

select count(*) from sys.all_objects where type = 'P' and name = 'sys_procedures_vu_prepare_proc1';
GO

select count(*) from sys.sql_modules where object_id = object_id('sys_procedures_vu_prepare_proc1');
GO

select parent_object_id from sys.objects where type = 'P' and name = 'sys_procedures_vu_prepare_proc1';
GO

select count(*) from sys.procedures where name = 'sys_procedures_vu_prepare_trig1' and type = 'TR' and parent_object_id = object_id('sys_procedures_vu_prepare_trig1') and parent_object_id != 0;
GO

USE master
GO

select count(*) from sys.procedures where name = 'sys_procedures_vu_prepare_proc1';
GO

select count(*) from sys.objects where type = 'P' and name = 'sys_procedures_vu_prepare_proc1';
GO

select count(*) from sys.all_objects where type = 'P' and name = 'sys_procedures_vu_prepare_proc1';
GO

select count(*) from sys.sql_modules where object_id = object_id('sys_procedures_vu_prepare_proc1');
GO

select parent_object_id from sys.objects where type = 'P' and name = 'sys_procedures_vu_prepare_proc1';
GO

select count(*) from sys.procedures where name = 'sys_procedures_vu_prepare_trig1' and type = 'TR' and parent_object_id = object_id('sys_procedures_vu_prepare_trig1') and parent_object_id != 0;
GO

select count(*) from sys.procedures where name = 'sys_procedures_vu_prepare_proc2';
GO

select count(*) from sys.objects where type = 'P' and name = 'sys_procedures_vu_prepare_proc2';
GO

select count(*) from sys.all_objects where type = 'P' and name = 'sys_procedures_vu_prepare_proc2';
GO

select count(*) from sys.sql_modules where object_id = object_id('sys_procedures_vu_prepare_proc2');
GO

USE sys_procedures_vu_prepare_db1
GO

select count(*) from sys.procedures where name = 'sys_procedures_vu_prepare_proc2';
GO

select count(*) from sys.objects where type = 'P' and name = 'sys_procedures_vu_prepare_proc2';
GO

select count(*) from sys.all_objects where type = 'P' and name = 'sys_procedures_vu_prepare_proc2';
GO

select count(*) from sys.sql_modules where object_id = object_id('sys_procedures_vu_prepare_proc2');
GO

USE master
GO

SELECT * FROM sys_procedures_vu_prepare_view
GO

EXEC sys_procedures_vu_prepare_proc
GO

SELECT dbo.sys_procedures_vu_prepare_func()
GO
