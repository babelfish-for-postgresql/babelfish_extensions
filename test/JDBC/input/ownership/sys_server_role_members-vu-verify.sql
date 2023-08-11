SELECT * from sys_server_role_members_vu_prepare_view;
GO

ALTER SERVER ROLE sysadmin ADD MEMBER sys_server_role_members_vu_prepare_login1;
GO

ALTER SERVER ROLE sysadmin ADD MEMBER sys_server_role_members_vu_prepare_login2;
GO

SELECT * from sys_server_role_members_vu_prepare_view;
GO

ALTER SERVER ROLE sysadmin DROP MEMBER sys_server_role_members_vu_prepare_login2;
GO

ALTER SERVER ROLE sysadmin ADD MEMBER sys_server_role_members_vu_prepare_login3;
GO

SELECT * from sys_server_role_members_vu_prepare_view;
GO

ALTER SERVER ROLE sysadmin DROP MEMBER sys_server_role_members_vu_prepare_login1;
GO

ALTER SERVER ROLE sysadmin DROP MEMBER sys_server_role_members_vu_prepare_login3;
GO

ALTER SERVER ROLE sysadmin DROP MEMBER sys_server_role_members_vu_prepare_login4;
GO

SELECT * from sys_server_role_members_vu_prepare_view;
GO