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

SELECT name, type, type_desc, default_database_name, default_language_name, credential_id, owning_principal_id, is_fixed_role
FROM sys.server_principals 
WHERE name =  'public';
GO

CREATE LOGIN serv_principal_test WITH PASSWORD = 'test';
GO

CREATE LOGIN [public] WITH PASSWORD = 'test';
GO

SELECT name, type, type_desc, default_database_name, default_language_name
FROM sys.server_principals 
WHERE name in ('jdbc_user', 'serv_principal_test') order by name;
GO

DROP LOGIN serv_principal_test;
GO

SELECT name, type, type_desc, default_database_name, default_language_name
FROM sys.server_principals 
WHERE name in ('jdbc_user', 'serv_principal_test');
GO

select name, principal_id, sid, type, type_desc
from sys.server_principals where name = 'public'
GO

select name, principal_id, sid,
suser_name(principal_id) as suser_name,
suser_sid(name) as suser_sid,
suser_sname(sid) as suser_sname,
suser_sname(suser_sid(name)) as name2
from sys.server_principals
where name = 'public'
GO

select suser_sid('public')
GO

select name, principal_id, sid, suser_name(principal_id) as suser_name, suser_sid(name) as suser_sid, suser_sname(sid) as suser_sname, suser_sname(suser_sid(name)) as name2 from sys.server_principals where name = 'pUbLiC'
GO

select suser_name(002)
GO

select suser_name(0000002)
GO

select suser_sid('PuBlIC')
GO

select user_name(1)
GO

select user_id('public')
GO
