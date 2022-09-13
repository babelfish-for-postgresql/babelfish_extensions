CREATE VIEW sys_database_mirroring_vu_prepare_view AS
SELECT * FROM sys.database_mirroring WHERE database_id = 1
GO

CREATE PROC sys_database_mirroring_vu_prepare_proc AS
SELECT * FROM sys.database_mirroring WHERE database_id = 1
GO

CREATE FUNCTION sys_database_mirroring_vu_prepare_func()
RETURNS INT
AS
BEGIN
	RETURN (SELECT mirroring_state FROM sys.database_mirroring WHERE database_id = 1)
END
GO
