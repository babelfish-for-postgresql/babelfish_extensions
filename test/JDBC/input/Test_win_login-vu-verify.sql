create user admin for login [xyz\admin]
GO

select login_name from sys.babelfish_authid_user_ext where rolname = 'master_admin';
GO

create user test for login [abc\test]
GO

select login_name from sys.babelfish_authid_user_ext where rolname = 'master_test';
GO

drop user test;
GO

drop user admin;
GO

drop login [abc\test];
GO

drop login [xyz\admin];
GO

exec babelfish_reset_domain_mapping;
GO
