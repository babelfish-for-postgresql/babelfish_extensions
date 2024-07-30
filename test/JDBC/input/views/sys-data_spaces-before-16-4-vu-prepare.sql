CREATE VIEW sys_data_spaces_vu_prepare_view AS
SELECT * FROM sys.data_spaces where type_desc = 'ROWS_FILEGROUP'
GO

CREATE PROC sys_data_spaces_vu_prepare_proc AS
SELECT * FROM sys.data_spaces where type_desc = 'ROWS_FILEGROUP'
GO

CREATE FUNCTION dbo.sys_data_spaces_vu_prepare_func()
RETURNS INT
AS
BEGIN
RETURN (SELECT count(*) FROM sys.data_spaces where type_desc = 'ROWS_FILEGROUP')
END
GO