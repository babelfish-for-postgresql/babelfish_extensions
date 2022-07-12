USE master
GO

CREATE VIEW sys_data_spaces_vu_prepare_view AS
SELECT * FROM sys.data_spaces
GO

CREATE PROC sys_data_spaces_vu_prepare_proc AS
SELECT * FROM sys.data_spaces
GO

CREATE FUNCTION dbo.sys_data_spaces_vu_prepare_func()
RETURNS INT
AS
BEGIN
RETURN (SELECT COUNT(*) FROM sys.data_spaces)
END
GO