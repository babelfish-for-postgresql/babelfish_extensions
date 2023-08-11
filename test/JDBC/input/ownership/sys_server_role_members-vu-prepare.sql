CREATE LOGIN sys_server_role_members_vu_prepare_login1 WITH PASSWORD = '123';
GO

CREATE LOGIN sys_server_role_members_vu_prepare_login2 WITH PASSWORD = '123';
GO

CREATE LOGIN sys_server_role_members_vu_prepare_login3 WITH PASSWORD = '123';
GO

CREATE LOGIN sys_server_role_members_vu_prepare_login4 WITH PASSWORD = '123';
GO

CREATE VIEW sys_server_role_members_vu_prepare_view AS
SELECT 
roles.name AS RolePrincipalName
, members.name AS MemberPrincipalName
FROM sys.server_role_members AS server_role_members
INNER JOIN sys.server_principals AS roles
    ON server_role_members.role_principal_id = roles.principal_id
INNER JOIN sys.server_principals AS members 
    ON server_role_members.member_principal_id = members.principal_id;
GO