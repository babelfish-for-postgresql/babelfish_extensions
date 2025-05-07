select * from sys.db_role_mapping where ISNULL(member_login, '') != '' order by database_name;
GO

select * from sys.db_role_mapping where ISNULL(member_login, '') = '' order by database_name;
GO

drop user if exists userof_sys_db_role_mapping_vu_login
GO

drop login sys_db_role_mapping_vu_login
GO