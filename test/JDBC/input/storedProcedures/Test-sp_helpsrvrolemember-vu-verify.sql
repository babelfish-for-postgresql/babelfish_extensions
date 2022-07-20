INSERT INTO test_sp_helpsrvrolemember_tbl (ServerRole, MemberName, MemberSID) EXEC sp_helpsrvrolemember
GO

SELECT * FROM test_sp_helpsrvrolemember_tbl
GO

ALTER SERVER ROLE sysadmin ADD MEMBER test_sp_helpsrvrolemember_login
GO

INSERT INTO test_sp_helpsrvrolemember_tbl (ServerRole, MemberName, MemberSID) EXEC sp_helpsrvrolemember 'sysadmin'
GO

TRUNCATE TABLE test_sp_helpsrvrolemember_tbl
GO

SELECT * FROM test_sp_helpsrvrolemember_tbl
GO

ALTER SERVER ROLE sysadmin DROP MEMBER test_sp_helpsrvrolemember_login
GO

INSERT INTO test_sp_helpsrvrolemember_tbl (ServerRole, MemberName, MemberSID) EXEC sp_helpsrvrolemember 'sysadmin'
GO

TRUNCATE TABLE test_sp_helpsrvrolemember_tbl
GO

SELECT * FROM test_sp_helpsrvrolemember_tbl
GO

EXEC sp_helpsrvrolemember 'error'
GO
