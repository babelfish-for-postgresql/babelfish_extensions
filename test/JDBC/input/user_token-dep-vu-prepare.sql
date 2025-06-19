create view dbo.user_token_vu as select name, suser_sname(sid), type, usage from sys.user_token;
GO
grant select on dbo.user_token_vu to public;
GO

create login user_token_login_with_dbrole with password = '12345678';
GO

create user u_user_token_login_with_dbrole for login user_token_login_with_dbrole;
GO

create login user_token_login_with_db_owner with password = '12345678';
GO

create user u_user_token_login_with_db_owner for login user_token_login_with_db_owner;
GO

create login user_token_login_is_dbo with password = '12345678';
GO

create database user_token_test_db;
GO

create view dbo.user_token_fixed_roles 
as
select name, sid from sys.user_token 
where name in ('db_owner', 'db_accessadmin', 'db_securityadmin', 'db_datareader', 'db_datawriter', 'db_ddladmin', 'db_backupoperator', 'db_denydatawriter', 'db_denydatareader') 
order by name
GO
grant select on dbo.user_token_fixed_roles to public;
GO

create login user_token_with_all_priv with password = '12345678'
GO
create user u_user_token_with_all_priv for login user_token_with_all_priv
GO
