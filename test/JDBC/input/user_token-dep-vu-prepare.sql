create view dbo.user_token_vu as select name, suser_sname(sid), type, usage from sys.user_token;
GO
grant select on dbo.user_token_vu to public;
GO

create login user_token_login_with_dbrole with password = '12345678';
GO

create user u_user_token_login_with_dbrole for login user_token_login_with_dbrole;
GO

-- create a db role and add the above user to the role
create role testrole;
GO
alter role testrole add member u_user_token_login_with_dbrole
GO