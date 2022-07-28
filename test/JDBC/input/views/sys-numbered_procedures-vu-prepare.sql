USE master
GO

CREATE VIEW sys_numbered_procedures_vu_prepare_view AS
SELECT * FROM sys.numbered_procedures
GO

CREATE PROC sys_numbered_procedures_vu_prepare_proc AS
SELECT * FROM sys.numbered_procedures 
GO

CREATE FUNCTION dbo.sys_numbered_procedures_vu_prepare_func()
RETURNS INT
AS
BEGIN
RETURN (SELECT count(*) FROM sys.numbered_procedures)
END
GO