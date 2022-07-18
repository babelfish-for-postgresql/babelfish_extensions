CREATE VIEW sys_database_mirroring_view_vu_prepare AS
SELECT * FROM sys.database_mirroring WHERE database_id = 1
GO

CREATE PROC sys_database_mirroring_proc_vu_prepare AS
SELECT * FROM sys.database_mirroring WHERE database_id = 1
GO

CREATE FUNCTION sys_database_mirroring_func_vu_prepare()
RETURNS INT
AS
BEGIN
	RETURN (SELECT mirroring_state FROM sys.database_mirroring WHERE database_id = 1)
END
GO
