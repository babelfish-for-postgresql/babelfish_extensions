drop user if exists sys_database_principals_vu_user 
drop user if exists sys_database_principals_vu_orphaned_user 
GO

drop login sys_database_principals_vu_login 
GO

drop database if exists sys_database_principals_db_different_owner 
drop login sys_database_principals_vu_login_with_sysadmin 
GO