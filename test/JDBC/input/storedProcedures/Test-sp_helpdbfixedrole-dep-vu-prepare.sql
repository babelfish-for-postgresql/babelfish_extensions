CREATE PROC test_sp_helpdbfixedrole_proc @rolename AS sys.SYSNAME = NULL
AS
BEGIN
	EXEC sp_helpdbfixedrole @rolename;
END
GO


CREATE FUNCTION dbo.test_sp_helpdbfixedrole_func() RETURNS INT
AS
BEGIN
DECLARE
	@tmp_sp_helpdbfixedrole TABLE(DbFixedRole sys.SYSNAME, Description sys.NVARCHAR(70));
	INSERT INTO @tmp_sp_helpdbfixedrole (DbFixedRole, Description) EXEC sp_helpdbfixedrole;
	RETURN (SELECT COUNT(*) FROM @tmp_sp_helpdbfixedrole);
END
GO


CREATE VIEW test_sp_helpdbfixedrole_view AS
SELECT dbo.test_sp_helpdbfixedrole_func() AS Description
GO
