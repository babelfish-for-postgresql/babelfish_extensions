SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.server_principals');
GO

SELECT name, type, type_desc, default_database_name, default_language_name, credential_id, owning_principal_id, is_fixed_role
FROM sys.server_principals 
WHERE name =  'jdbc_user';
GO

SELECT name, type, type_desc, default_database_name, default_language_name, credential_id, owning_principal_id, is_fixed_role
FROM sys.server_principals 
WHERE name =  'sysadmin';
GO
