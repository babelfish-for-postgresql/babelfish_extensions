SELECT	roles.name AS RolePrincipalName
	, members.name AS MemberPrincipalName
FROM sys.server_role_members AS server_role_members
INNER JOIN sys.server_principals AS roles
    ON server_role_members.role_principal_id = roles.principal_id
INNER JOIN sys.server_principals AS members 
    ON server_role_members.member_principal_id = members.principal_id  
;
GO

ALTER SERVER ROLE sysadmin ADD MEMBER sys_server_role_members_vu_prepare_login1;
GO

ALTER SERVER ROLE sysadmin ADD MEMBER sys_server_role_members_vu_prepare_login2;
GO

SELECT	roles.name AS RolePrincipalName
	, members.name AS MemberPrincipalName
FROM sys.server_role_members AS server_role_members
INNER JOIN sys.server_principals AS roles
    ON server_role_members.role_principal_id = roles.principal_id
INNER JOIN sys.server_principals AS members 
    ON server_role_members.member_principal_id = members.principal_id  
;
GO

ALTER SERVER ROLE sysadmin DROP MEMBER sys_server_role_members_vu_prepare_login2;
GO

ALTER SERVER ROLE sysadmin ADD MEMBER sys_server_role_members_vu_prepare_login3;
GO

SELECT	roles.name AS RolePrincipalName
	, members.name AS MemberPrincipalName
FROM sys.server_role_members AS server_role_members
INNER JOIN sys.server_principals AS roles
    ON server_role_members.role_principal_id = roles.principal_id
INNER JOIN sys.server_principals AS members 
    ON server_role_members.member_principal_id = members.principal_id  
;
GO

ALTER SERVER ROLE sysadmin DROP MEMBER sys_server_role_members_vu_prepare_login1;
GO

ALTER SERVER ROLE sysadmin DROP MEMBER sys_server_role_members_vu_prepare_login3;
GO

ALTER SERVER ROLE sysadmin DROP MEMBER sys_server_role_members_vu_prepare_login4;
GO

SELECT	roles.name AS RolePrincipalName
	, members.name AS MemberPrincipalName
FROM sys.server_role_members AS server_role_members
INNER JOIN sys.server_principals AS roles
    ON server_role_members.role_principal_id = roles.principal_id
INNER JOIN sys.server_principals AS members 
    ON server_role_members.member_principal_id = members.principal_id  
;
GO