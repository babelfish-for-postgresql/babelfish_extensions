CREATE VIEW sys_assembly_types_view AS
SELECT * FROM sys.assembly_types
GO

CREATE PROC sys_assembly_types_proc AS
SELECT * FROM sys.assembly_types
GO

CREATE FUNCTION sys_assembly_types_func()
RETURNS INT
AS
BEGIN
RETURN (SELECT COUNT(*) FROM sys.assembly_types)
END
GO
