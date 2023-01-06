SELECT definition FROM sys.check_constraints where name LIKE '%sys_check_constraints%' ORDER BY name;
GO

SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.check_constraints');
GO