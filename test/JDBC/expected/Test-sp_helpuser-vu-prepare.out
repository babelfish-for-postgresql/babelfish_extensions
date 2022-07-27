CREATE PROCEDURE Test_sp_helpuser_vu_prepare_check_helpuser @user_or_role AS SYS.SYSNAME = NULL
AS
BEGIN
	DECLARE @tablevar TABLE(userName sys.SYSNAME, roleName sys.SYSNAME, loginName sys.SYSNAME NULL, defdb sys.SYSNAME NULL, defschema sys.SYSNAME, userid INT, sid sys.VARBINARY(85));
	INSERT INTO @tablevar(userName, roleName, loginName, defdb, defschema, userid, sid) EXEC sp_helpuser @user_or_role;
	SELECT UserName, RoleName, (CASE WHEN (loginName IS NULL) THEN 0 ELSE 1 END), defdb, defschema, user_name(userid), (CASE WHEN (sid IS NULL) THEN 0 ELSE 1 END) from @tablevar;
END;
GO

CREATE DATABASE Test_sp_helpuser_vu_prepare_db;
GO

USE Test_sp_helpuser_vu_prepare_db;
GO

CREATE PROCEDURE Test_sp_helpuser_vu_prepare_check_helpuser @user_or_role AS SYS.SYSNAME = NULL
AS
BEGIN
	DECLARE @tablevar TABLE(userName sys.SYSNAME, roleName sys.SYSNAME, loginName sys.SYSNAME NULL, defdb sys.SYSNAME NULL, defschema sys.SYSNAME, userid INT, sid sys.VARBINARY(85));
	INSERT INTO @tablevar(userName, roleName, loginName, defdb, defschema, userid, sid) EXEC sp_helpuser @user_or_role;
	SELECT UserName, RoleName, (CASE WHEN (loginName IS NULL) THEN 0 ELSE 1 END), defdb, defschema, user_name(userid), (CASE WHEN (sid IS NULL) THEN 0 ELSE 1 END) from @tablevar;
END;
GO

