SELECT definition FROM sys.default_constraints where name LIKE '%sys_default_definitions%'
GO

SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.default_constraints');
GO