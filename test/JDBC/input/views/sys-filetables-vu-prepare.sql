USE master
GO

CREATE VIEW sys_filetables_vu_prepare_view AS
SELECT * FROM sys.filetables
GO

CREATE PROC sys_filetables_vu_prepare_proc AS
SELECT * FROM sys.filetables
GO

CREATE FUNCTION dbo.sys_filetables_vu_prepare_func()
RETURNS INT
AS
BEGIN
RETURN (SELECT COUNT(*) FROM sys.filetables)
END
GO