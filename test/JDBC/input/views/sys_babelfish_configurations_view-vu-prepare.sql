CREATE VIEW sys_babelfish_configurations_view_vu_prepare_view AS 
SELECT COUNT(*) FROM sys.babelfish_configurations_view
GO

CREATE PROC sys_babelfish_configurations_view_vu_prepare_proc AS
SELECT COUNT(*) FROM sys.babelfish_configurations_view
GO

CREATE FUNCTION sys_babelfish_configurations_view_vu_prepare_func()
RETURNS INT
AS
BEGIN
RETURN (SELECT COUNT(*) FROM sys.babelfish_configurations_view)
END
GO
