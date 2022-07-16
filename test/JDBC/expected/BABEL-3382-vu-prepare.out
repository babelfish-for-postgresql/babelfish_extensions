USE master;
GO

CREATE TABLE sys_sysobjects_test_table(c1 int)
GO

CREATE VIEW sys_sysobjects_view AS
SELECT COUNT(*) FROM sys.sysobjects s where s.name = 'sys_sysobjects_test_table'
GO

CREATE PROC sys_sysobjects_proc AS
SELECT COUNT(*) FROM sys.sysobjects s where s.name = 'sys_sysobjects_test_table'
GO

CREATE FUNCTION dbo.sys_sysobjects_func()
RETURNS INT
AS
BEGIN
RETURN (SELECT COUNT(*) FROM sys.sysobjects s where s.name = 'sys_sysobjects_test_table')
END
GO
