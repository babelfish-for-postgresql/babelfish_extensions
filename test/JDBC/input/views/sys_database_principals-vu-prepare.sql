-- create a separate DB for users
create database sys_database_principals_vu_db
GO

create login sys_database_principals_vu_login with password = '12345678'
GO

create user sys_database_principals_vu_user for login sys_database_principals_vu_login
GO

-- create a login which is a member of sysadmin server role
create login sys_database_principals_vu_login_with_sysadmin with password = '12345678'
GO

create login sys_database_principals_vu_login_tbd with password = '12345678'
GO

create user sys_database_principals_vu_orphaned_user for login sys_database_principals_vu_login_tbd
GO

drop login sys_database_principals_vu_login_tbd
GO

create database sys_database_principals_db_different_owner
GO

-- creating a login without any permissions
create database sys_database_principals_vu_db_another
GO
create login login_without_any_permissions with password = '12345678'
GO

create view sys_database_principals_another_vu as select * from database_principals;
GO

create view sys_database_principals_fixed_roles 
as
select name, sid from sys.database_principals 
where name in ('db_owner', 'db_accessadmin', 'db_securityadmin', 'db_datareader', 'db_datawriter', 'db_ddladmin', 'db_backupoperator', 'db_denydatawriter', 'db_denydatareader') 
order by name
GO

create function sys_database_principals_another_func()
returns table
as
return (select * from database_principals)
GO