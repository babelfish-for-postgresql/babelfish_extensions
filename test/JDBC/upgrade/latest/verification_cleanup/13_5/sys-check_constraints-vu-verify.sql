SELECT definition FROM sys.check_constraints where name LIKE '%sys_check_constraints%' ORDER BY name;
GO

SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.check_constraints');
GO

EXEC sys_check_constraints_vu_prepare_proc;
GO

SELECT * FROM sys_check_constraints_vu_prepare_func();
GO

SELECT * FROM sys_check_constraints_vu_prepare_view;
GO