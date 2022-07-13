CREATE VIEW sys_database_mirroring_view AS
SELECT * FROM sys.database_mirroring WHERE database_id = 1
GO

CREATE PROC sys_database_mirroring_proc AS
SELECT * FROM sys.database_mirroring WHERE database_id = 1
GO

CREATE FUNCTION sys_database_mirroring_func()
RETURNS INT
AS
BEGIN
	RETURN (SELECT mirroring_state FROM sys.database_mirroring WHERE database_id = 1)
END
GO
