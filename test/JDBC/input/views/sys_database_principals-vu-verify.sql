use sys_database_principals_vu_db
GO

-- create a login which is a member of sysadmin server role
create login sys_database_principals_vu_login_with_sysadmin with password = '12345678'
alter server role sysadmin add member sys_database_principals_vu_login_with_sysadmin
GO

-- change db owner to the new sysadmin login
alter authorization on database::sys_database_principals_db_different_owner to sys_database_principals_vu_login_with_sysadmin
GO

select suser_sname(sid) from database_principals where name = 'dbo';
GO

select suser_sname(sid) from database_principals where name = 'sys_database_principals_vu_user'
GO

select suser_sname(sid) from database_principals where name in ('sys_database_principals_vu_orphaned_user', 'db_owner', 'db_securityadmin', 'db_datawriter', 'db_accessadmin', 'db_datareader', 'db_ddladmin')
GO

select name, suser_sname(sid) from database_principals order by name;
GO

use sys_database_principals_db_different_owner
GO

select suser_sname(sid) from database_principals where name = 'dbo';
GO

use master
GO

-- filtering only logins which are created within this test
-- (sys_database_principals_vu_login, sys_database_principals_vu_login_tbd, jdbc_user <masteruser>)
select suser_sname(sid), name, type, default_schema_name from sys_database_principals_another_vu
where suser_sname(sid) IS NULL OR suser_sname(sid) IN ('sys_database_principals_vu_login', 'sys_database_principals_vu_login_tbd', 'jdbc_user')
order by name;
GO

select suser_sname(sid), name, cast(type as char) from sys_database_principals_another_func()
where suser_sname(sid) IS NULL OR suser_sname(sid) IN ('sys_database_principals_vu_login', 'sys_database_principals_vu_login_tbd', 'jdbc_user')
order by name;
GO