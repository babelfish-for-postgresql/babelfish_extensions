SELECT ac.name,tp.name as type_name FROM sys.all_columns ac
LEFT JOIN sys.types tp ON tp.system_type_id = ac.system_type_id
WHERE ac.object_id = object_id('sys.server_principals') ORDER BY ac.name;
GO

SELECT ac.name,tp.name as type_name FROM sys.all_columns ac
LEFT JOIN sys.types tp ON tp.system_type_id = ac.system_type_id
WHERE ac.object_id = object_id('sys.database_principals') ORDER BY ac.name;
GO