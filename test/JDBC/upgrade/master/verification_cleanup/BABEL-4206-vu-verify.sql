-- check roles and users
-- login_name should be empty after database-level restore
EXEC babel_4206_vu_prepare_user_ext;
GO

-- check role membership is intact
EXEC babel_4206_vu_prepare_role_members;
GO

-- verify that users can be mapped to new logins
CREATE LOGIN babel_4206_vu_prepare_login1 WITH PASSWORD = 'abc';
GO

CREATE LOGIN babel_4206_vu_prepare_login2 WITH PASSWORD = 'abc';
GO

ALTER USER babel_4206_vu_prepare_user1 WITH LOGIN = babel_4206_vu_prepare_login1;
GO

ALTER USER babel_4206_vu_prepare_user2 WITH LOGIN = babel_4206_vu_prepare_login2;
GO

-- again check updated users
EXEC babel_4206_vu_prepare_user_ext;
GO
