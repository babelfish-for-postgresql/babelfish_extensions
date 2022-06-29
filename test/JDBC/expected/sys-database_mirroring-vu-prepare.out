CREATE VIEW sys_database_mirroring_view AS
SELECT * FROM sys.database_mirroring WHERE database_id = 1
GO

CREATE PROC sys_database_mirroring_proc AS
SELECT * FROM sys.database_mirroring WHERE database_id = 1
GO

CREATE FUNCTION sys_database_mirroring_func()
RETURNS TABLE
AS
RETURN (SELECT * FROM sys.database_mirroring WHERE database_id = 1)
GO
