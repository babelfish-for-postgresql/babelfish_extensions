SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.schemas');
GO

SELECT name FROM sys.schemas 
WHERE name = 'dbo';
GO

SELECT name FROM sys.schemas 
WHERE name in ('dbo', 'sys_schema_test1', 'sys_schema_test2') ORDER BY name;
GO
