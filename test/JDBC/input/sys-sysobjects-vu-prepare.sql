USE master;
GO

CREATE TABLE sys_sysobjects_vu_prepare_table(c1 int)
GO

CREATE VIEW sys_sysobjects_vu_prepare_view AS
SELECT COUNT(*) FROM sys.sysobjects s where s.name = 'sys_sysobjects_vu_prepare_table'
GO

CREATE PROC sys_sysobjects_vu_prepare_proc AS
SELECT COUNT(*) FROM sys.sysobjects s where s.name = 'sys_sysobjects_vu_prepare_table'
GO

CREATE FUNCTION dbo.sys_sysobjects_vu_prepare_func()
RETURNS INT
AS
BEGIN
RETURN (SELECT COUNT(*) FROM sys.sysobjects s where s.name = 'sys_sysobjects_vu_prepare_table')
END
GO
