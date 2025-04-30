select suser_sname(sid) from database_principals where name = 'dbo';
GO

select suser_sname(sid) from database_principals where name = 'sys_database_principals_vu_user'
GO

select suser_sname(sid) from database_principals where name = 'sys_database_principals_vu_orphaned_user' 
OR name in ('db_owner', 'db_securityadmin', 'db_datawriter', 'db_accessadmin', 'db_datareader', 'db_ddladmin')
GO

select name, suser_sname(sid) from database_principals order by name;
GO

use sys_database_principals_db_different_owner
select suser_sname(sid) from database_principals where name = 'dbo';
GO
