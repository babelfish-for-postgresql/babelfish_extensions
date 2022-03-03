CREATE LOGIN tester WITH PASSWORD = '12121212';
GO

CREATE USER test_user FOR LOGIN tester;
GO

SELECT suser_sname(sid) from database_principals where name = 'test_user';
GO

DROP USER test_user;
GO

DROP LOGIN tester;
GO
