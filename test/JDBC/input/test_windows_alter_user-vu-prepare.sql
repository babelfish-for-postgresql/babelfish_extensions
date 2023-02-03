create login [bbf\alter_user] from windows;
GO

create login [bbf\alter_user2] from windows;
GO

create user [bbf\alter_user_test] for login [bbf\alter_user];
GO

create schema ad_schema;
GO