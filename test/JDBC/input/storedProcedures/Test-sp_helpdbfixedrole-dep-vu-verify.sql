EXEC test_sp_helpdbfixedrole_proc
GO

EXEC test_sp_helpdbfixedrole_proc 'db_owner'
GO

-- INSERT EXEC is not allowed inside a function, so capture sp_helpdbfixedrole
-- output into a table variable directly in the batch instead.
DECLARE @tmp_sp_helpdbfixedrole TABLE(DbFixedRole sys.SYSNAME, Description sys.NVARCHAR(70));
INSERT INTO @tmp_sp_helpdbfixedrole (DbFixedRole, Description) EXEC sp_helpdbfixedrole;
SELECT COUNT(*) FROM @tmp_sp_helpdbfixedrole;
GO

DECLARE @tmp_sp_helpdbfixedrole2 TABLE(DbFixedRole sys.SYSNAME, Description sys.NVARCHAR(70));
INSERT INTO @tmp_sp_helpdbfixedrole2 (DbFixedRole, Description) EXEC sp_helpdbfixedrole;
SELECT COUNT(*) FROM @tmp_sp_helpdbfixedrole2;
GO

EXEC test_sp_helpdbfixedrole_proc 'DB_securityadmin'
GO

EXEC test_sp_helpdbfixedrole_proc 'error'
GO
